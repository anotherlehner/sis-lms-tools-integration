require "minitest/autorun"
require "rack/mock"
require "jwt"
require_relative "../app"

class AcmeGuessTheNumberTest < Minitest::Test
  PLATFORM_ISSUER = "http://127.0.0.1:3000"
  TOOL_URL = "http://127.0.0.1:3002"
  CLIENT_ID = "acme-guess-the-number"
  DEPLOYMENT_ID = "local-acme"
  PLATFORM_KID = "lms-platform-key"

  def setup
    @platform_key = OpenSSL::PKey::RSA.generate(2048)
    @tool_key = OpenSSL::PKey::RSA.generate(2048)
    @submissions = []
    @app = Acme::App.new(
      platform_issuer: PLATFORM_ISSUER,
      client_id: CLIENT_ID,
      deployment_id: DEPLOYMENT_ID,
      tool_base_url: TOOL_URL,
      private_key: @tool_key,
      jwks_fetcher: -> {
        JSON.parse(JSON.generate(
          "keys" => [JWT::JWK.new(@platform_key, kid: PLATFORM_KID).export.merge(use: "sig", alg: "RS256")]
        ))
      },
      score_submitter: ->(lineitem, user_id, attempts, comment) {
        @submissions << [lineitem, user_id, attempts, comment]
      }
    )
    @request = Rack::MockRequest.new(@app)
  end

  def test_login_redirects_to_the_platform_authorization_endpoint
    response = @request.get("/lti/login", params: {
      iss: PLATFORM_ISSUER,
      client_id: CLIENT_ID,
      login_hint: "opaque-login-hint",
      target_link_uri: "#{TOOL_URL}/lti/launch"
    })

    assert_equal 303, response.status
    authorization = URI(response["Location"])
    params = Rack::Utils.parse_query(authorization.query)
    assert_equal "#{PLATFORM_ISSUER}/lti/authorize", authorization.to_s.split("?", 2).first
    assert_equal "id_token", params["response_type"]
    assert_equal "form_post", params["response_mode"]
    assert_equal "opaque-login-hint", params["login_hint"]
    assert_equal "#{TOOL_URL}/lti/launch", params["redirect_uri"]
  end

  def test_launch_rejects_an_id_token_for_another_client
    state, nonce = login_state
    token = launch_token(nonce, audience: "another-tool")

    response = @request.post("/lti/launch", params: { state: state, id_token: token })

    assert_equal 401, response.status
    assert_empty @submissions
  end

  def test_correct_guess_reports_score_and_attempt_count_to_ags
    state, nonce = login_state
    token = launch_token(nonce)
    launch_response = @request.post("/lti/launch", params: { state: state, id_token: token })

    assert_equal 303, launch_response.status, launch_response.body
    cookie = launch_response["Set-Cookie"].split(";", 2).first
    game = @app.instance_variable_get(:@games).values.first
    wrong_guess = game[:secret] == 1 ? 100 : 1

    wrong_response = @request.post("/guess", "HTTP_COOKIE" => cookie, params: { guess: wrong_guess })
    assert_equal 200, wrong_response.status
    assert_match(/Too (low|high)/, wrong_response.body)
    assert_equal 1, game[:attempts]

    complete_response = @request.post("/guess", "HTTP_COOKIE" => cookie, params: { guess: game[:secret] })

    assert_equal 200, complete_response.status
    assert_match(/Correct! You solved it in 2 guesses/, complete_response.body)
    assert_match(/Result sent to the LMS/, complete_response.body)
    assert_equal [[
      "#{PLATFORM_ISSUER}/lti/ags/line_items/12/sections/34",
      "student-sourced-id",
      2,
      "Solved in 2 guesses"
    ]], @submissions
  end

  def test_invalid_guess_does_not_increment_attempt_count
    state, nonce = login_state
    launch_response = @request.post("/lti/launch", params: { state: state, id_token: launch_token(nonce) })
    assert_equal 303, launch_response.status, launch_response.body
    cookie = launch_response["Set-Cookie"].split(";", 2).first

    response = @request.post("/guess", "HTTP_COOKIE" => cookie, params: { guess: "101" })

    assert_equal 422, response.status
    assert_match(/whole number from 1 to 100/, response.body)
    assert_equal 0, @app.instance_variable_get(:@games).values.first[:attempts]
  end

  private

  def login_state
    login = @request.get("/lti/login", params: {
      iss: PLATFORM_ISSUER,
      client_id: CLIENT_ID,
      login_hint: "opaque-login-hint",
      target_link_uri: "#{TOOL_URL}/lti/launch"
    })
    Rack::Utils.parse_query(URI(login["Location"]).query).values_at("state", "nonce")
  end

  def launch_token(nonce, audience: CLIENT_ID)
    now = Time.now.to_i
    JWT.encode({
      iss: PLATFORM_ISSUER,
      aud: audience,
      sub: "student-sourced-id",
      iat: now,
      exp: now + 300,
      nonce: nonce,
      "https://purl.imsglobal.org/spec/lti/claim/deployment_id" => DEPLOYMENT_ID,
      "https://purl.imsglobal.org/spec/lti/claim/message_type" => "LtiResourceLinkRequest",
      "https://purl.imsglobal.org/spec/lti/claim/version" => "1.3.0",
      "https://purl.imsglobal.org/spec/lti/claim/target_link_uri" => "#{TOOL_URL}/lti/launch",
      "https://purl.imsglobal.org/spec/lti/claim/resource_link" => { id: "activity-sourced-id" },
      "https://purl.imsglobal.org/spec/lti/claim/context" => { id: "section-sourced-id" },
      "https://purl.imsglobal.org/spec/lti/claim/launch_presentation" => {
        return_url: "#{PLATFORM_ISSUER}/courses/1/sections/2"
      },
      "https://purl.imsglobal.org/spec/lti-ags/claim/endpoint" => {
        lineitem: "#{PLATFORM_ISSUER}/lti/ags/line_items/12/sections/34",
        scope: [Acme::App::AGS_SCORE_SCOPE]
      }
    }, @platform_key, "RS256", { kid: PLATFORM_KID })
  end
end
