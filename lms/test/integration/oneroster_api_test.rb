require "test_helper"
require "minitest/mock"

class OneRosterApiTest < ActionDispatch::IntegrationTest
  ROSTER_SCOPE = "https://purl.imsglobal.org/spec/or/v1p2/scope/roster.readonly"
  GRADEBOOK_SCOPE = "https://purl.imsglobal.org/spec/or/v1p2/scope/gradebook.readonly"

  setup do
    @previous_env = %w[ONEROSTER_CLIENT_ID ONEROSTER_CLIENT_SECRET SYNC_CONTROL_TOKEN].to_h do |key|
      [key, ENV[key]]
    end
    ENV["ONEROSTER_CLIENT_ID"] = "lms-consumer"
    ENV["ONEROSTER_CLIENT_SECRET"] = "lms-consumer-secret"
    ENV["SYNC_CONTROL_TOKEN"] = "sync-secret"
  end

  teardown do
    @previous_env.each { |key, value| value ? ENV[key] = value : ENV.delete(key) }
  end

  test "issues a scoped OAuth bearer token and protects gradebook endpoints" do
    role = Role.create!(name: "student")
    student = User.create!(
      first_name: "Sam",
      last_name: "Student",
      identifier: "student-id",
      username: "student",
      password: "password"
    )
    student.roles << role
    course = Course.create!(title: "Science")
    section = Section.create!(course: course, name: "Section A")
    Enrollment.create!(section: section, user: student)
    activity = Activity.create!(course: course, title: "Lab")
    activity.activity_completions.find_by!(user: student).update!(score: 92)

    token = get_token(GRADEBOOK_SCOPE)
    get "/ims/oneroster/v1p2/lineItems?limit=1&offset=0",
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
    assert_equal 1, response.parsed_body.fetch("lineItems").length
    get "/ims/oneroster/v1p2/results", headers: { "Authorization" => "Bearer invalid" }
    assert_response :unauthorized
  end

  test "rejects an incorrect client credential and unsupported scope" do
    post "/ims/oneroster/v1p2/oauth/token",
      params: { grant_type: "client_credentials", scope: GRADEBOOK_SCOPE },
      headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("wrong", "wrong") }
    assert_response :unauthorized

    post "/ims/oneroster/v1p2/oauth/token",
      params: { grant_type: "client_credentials", scope: ROSTER_SCOPE },
      headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("lms-consumer", "lms-consumer-secret") }
    assert_response :bad_request
  end

  test "control endpoint requires its separate token and starts roster consumption" do
    post "/sync/roster"
    assert_response :unauthorized

    synchronizer = Object.new
    synchronizer.define_singleton_method(:call) { { users: 1, courses: 1, classes: 1, enrollments: 1 } }
    OneRoster::RosterSynchronizer.stub :new, -> { synchronizer } do
      post "/sync/roster", headers: { "Authorization" => "Bearer sync-secret" }
    end

    assert_response :success
    assert_equal "sis_to_lms", response.parsed_body.fetch("direction")
    assert_equal 1, response.parsed_body.dig("counts", "users")
  end

  private

  def get_token(scope)
    post "/ims/oneroster/v1p2/oauth/token",
      params: { grant_type: "client_credentials", scope: scope },
      headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("lms-consumer", "lms-consumer-secret") }
    assert_response :success
    response.parsed_body.fetch("access_token")
  end
end
