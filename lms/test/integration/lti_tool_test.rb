require "test_helper"
require "minitest/mock"

class LtiToolTest < ActionDispatch::IntegrationTest
  setup do
    @student_role = Role.create!(name: "student")
    @instructor_role = Role.create!(name: "instructor")
    @student = create_user("student", @student_role)
    @instructor = create_user("instructor", @instructor_role)
    @course = Course.create!(title: "Math")
    @section = Section.create!(course: @course, name: "Section A")
    Enrollment.create!(section: @section, user: @student)
    TeachingAssignment.create!(section: @section, user: @instructor)
    @activity = Activity.create!(
      course: @course,
      title: "Guess the Number",
      activity_type: "tool",
      content: "Acme Guess the Number"
    )
    @tool_key = OpenSSL::PKey::RSA.generate(2048)
  end

  test "publishes the LTI platform discovery document and JWKS" do
    get "/.well-known/openid-configuration"

    assert_response :success
    assert_equal Lti::Platform::ISSUER, response.parsed_body.fetch("issuer")
    assert_equal Lti::Platform.jwks_uri, response.parsed_body.fetch("jwks_uri")

    get lti_jwks_path

    assert_response :success
    keys = response.parsed_body.fetch("keys")
    assert_equal 1, keys.length
    jwk = keys.first
    assert_equal "RSA", jwk.fetch("kty")
    assert_equal Lti::Platform::KEY_ID, jwk.fetch("kid")
    refute jwk.key?("d")
  end

  test "launches the registered tool and consumes the LMS login hint once" do
    sign_in_student
    get launch_course_section_activity_path(@course, @section, @activity)

    assert_redirected_to %r{\A#{Regexp.escape(Lti::Platform.tool_login_url)}\?}
    redirect_params = Rack::Utils.parse_query(URI(response.location).query)
    login_hint = redirect_params.fetch("login_hint")
    get lti_authorize_path, params: {
      client_id: Lti::Platform::CLIENT_ID,
      redirect_uri: Lti::Platform.tool_launch_url,
      response_type: "id_token",
      response_mode: "form_post",
      scope: "openid",
      prompt: "none",
      state: "state-from-tool",
      nonce: "nonce-from-tool",
      login_hint: login_hint
    }

    assert_response :success
    assert_select "form[method=post][action='#{Lti::Platform.tool_launch_url}']"
    assert_select "input[name=state][value='state-from-tool']"
    id_token = response.body.match(/name="id_token" value="([^"]+)"/)[1]
    claims, = JWT.decode(id_token, Lti::Platform.private_key.public_key, true, algorithms: ["RS256"])
    assert_equal @student.one_roster_sourced_id, claims.fetch("sub")
    assert_equal "nonce-from-tool", claims.fetch("nonce")
    assert_equal "LtiResourceLinkRequest", claims.fetch("https://purl.imsglobal.org/spec/lti/claim/message_type")

    get lti_authorize_path, params: {
      client_id: Lti::Platform::CLIENT_ID,
      redirect_uri: Lti::Platform.tool_launch_url,
      response_type: "id_token",
      response_mode: "form_post",
      scope: "openid",
      prompt: "none",
      state: "replayed-state",
      nonce: "replayed-nonce",
      login_hint: login_hint
    }

    assert_response :bad_request
  end

  test "rejects tool launch without an enrolled student session" do
    other_student = create_user("other", @student_role)
    post lms_login_create_path, params: { username: other_student.username, password: other_student.username }

    get launch_course_section_activity_path(@course, @section, @activity)

    assert_redirected_to root_path
    assert_equal 0, LtiLaunch.count
  end

  test "instructors can add the Acme tool and students see its launch link in the course" do
    existing_tool_count = @course.activities.where(activity_type: "tool", title: "Guess the Number").count
    sign_in(@instructor)
    post create_tool_course_section_activities_path(@course, @section)

    assert_redirected_to course_section_path(@course, @section)
    assert_equal existing_tool_count + 1,
      @course.activities.where(activity_type: "tool", title: "Guess the Number").count

    sign_in_student
    get course_section_path(@course, @section)

    assert_response :success
    assert_select "a[href='#{launch_course_section_activity_path(@course, @section, @activity)}']", text: "Launch Guess the Number"
  end

  test "accepts an AGS score from the registered tool and stores the guess count" do
    access_token = issue_ags_token
    line_item_url = "/lti/ags/line_items/#{@activity.id}/sections/#{@section.id}"
    score_url = "#{line_item_url}/scores"

    get line_item_url, headers: { "Authorization" => "Bearer #{access_token}" }
    assert_response :success
    assert_equal Lti::Platform::ISSUER + line_item_url, response.parsed_body.fetch("id")

    post score_url, params: {
      userId: @student.one_roster_sourced_id,
      scoreGiven: 100,
      scoreMaximum: 100,
      comment: "Solved in 4 guesses",
      timestamp: Time.current.utc.iso8601,
      activityProgress: "Completed",
      gradingProgress: "FullyGraded"
    }.to_json, headers: {
      "Authorization" => "Bearer #{access_token}",
      "Content-Type" => "application/vnd.ims.lis.v1.score+json"
    }

    assert_response :no_content
    completion = @activity.activity_completions.find_by!(user: @student)
    assert_equal 100, completion.score
    assert_equal 4, completion.attempt_count
    assert completion.completed_at

    sign_in(@instructor)
    get course_section_gradebook_path(@course, @section)
    assert_response :success
    assert_select "p", text: "Solved in 4 guesses"
  end

  test "rejects scores without an AGS bearer token or an enrolled learner" do
    score_url = "/lti/ags/line_items/#{@activity.id}/sections/#{@section.id}/scores"
    payload = {
      userId: @student.one_roster_sourced_id,
      scoreGiven: 100,
      scoreMaximum: 100,
      comment: "Solved in 1 guess",
      activityProgress: "Completed",
      gradingProgress: "FullyGraded"
    }
    post score_url, params: payload, as: :json
    assert_response :unauthorized

    access_token = issue_ags_token
    other_student = create_user("other", @student_role)
    post score_url, params: payload.merge(userId: other_student.one_roster_sourced_id),
      headers: { "Authorization" => "Bearer #{access_token}" }, as: :json
    assert_response :unprocessable_content
    assert_not @activity.activity_completions.exists?(user: other_student)
  end

  private

  def create_user(username, role)
    user = User.create!(
      first_name: username.capitalize,
      last_name: "Test",
      identifier: "identifier-#{username}",
      username: username,
      password: username
    )
    user.roles << role
    user
  end

  def sign_in_student
    post lms_login_create_path, params: { username: @student.username, password: @student.username }
  end

  def sign_in(user)
    post lms_login_create_path, params: { username: user.username, password: user.username }
  end

  def issue_ags_token
    now = Time.current.to_i
    assertion = JWT.encode({
      iss: Lti::Platform::CLIENT_ID,
      sub: Lti::Platform::CLIENT_ID,
      aud: Lti::Platform.token_endpoint,
      iat: now,
      exp: now + 60,
      jti: SecureRandom.uuid
    }, @tool_key, "RS256", { kid: Lti::Platform::TOOL_KEY_ID })

    Lti::Platform.stub(:tool_public_key, @tool_key.public_key) do
      post lti_oauth_token_path, params: {
        grant_type: "client_credentials",
        client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        client_assertion: assertion,
        scope: Lti::Platform::AGS_SCORE_SCOPE
      }
    end

    assert_response :success
    response.parsed_body.fetch("access_token")
  end
end
