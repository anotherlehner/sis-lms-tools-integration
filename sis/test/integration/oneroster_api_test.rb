require "test_helper"
require "minitest/mock"

class OneRosterApiTest < ActionDispatch::IntegrationTest
  ROSTER_SCOPE = "https://purl.imsglobal.org/spec/or/v1p2/scope/roster.readonly"
  GRADEBOOK_SCOPE = "https://purl.imsglobal.org/spec/or/v1p2/scope/gradebook.readonly"

  setup do
    @previous_env = %w[ONEROSTER_CLIENT_ID ONEROSTER_CLIENT_SECRET SYNC_CONTROL_TOKEN].to_h do |key|
      [key, ENV[key]]
    end
    ENV["ONEROSTER_CLIENT_ID"] = "sis-consumer"
    ENV["ONEROSTER_CLIENT_SECRET"] = "sis-consumer-secret"
    ENV["SYNC_CONTROL_TOKEN"] = "sync-secret"
  end

  teardown do
    @previous_env.each { |key, value| value ? ENV[key] = value : ENV.delete(key) }
  end

  test "issues a scoped OAuth bearer token and protects roster endpoints" do
    token = get_token(ROSTER_SCOPE)

    get "/ims/oneroster/v1p2/orgs?limit=1&offset=0",
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
    payload = response.parsed_body
    assert_equal 1, payload.fetch("orgs").length
    assert_equal "Default School", payload.fetch("orgs").first.fetch("name")
  end

  test "rejects invalid client credentials, unsupported scope, and missing bearer token" do
    post "/ims/oneroster/v1p2/oauth/token",
      params: { grant_type: "client_credentials", scope: ROSTER_SCOPE },
      headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("wrong", "wrong") }
    assert_response :unauthorized

    post "/ims/oneroster/v1p2/oauth/token",
      params: { grant_type: "client_credentials", scope: GRADEBOOK_SCOPE },
      headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("sis-consumer", "sis-consumer-secret") }
    assert_response :bad_request

    get "/ims/oneroster/v1p2/users"
    assert_response :unauthorized
  end

  test "control endpoint requires its separate token and reports a completed pull" do
    post "/sync/gradebook"
    assert_response :unauthorized

    synchronizer = Object.new
    synchronizer.define_singleton_method(:call) { { imported: 2, skipped_unknown_students: 0 } }
    OneRoster::GradebookSynchronizer.stub :new, -> { synchronizer } do
      post "/sync/gradebook", headers: { "Authorization" => "Bearer sync-secret" }
    end

    assert_response :success
    assert_equal "lms_to_sis", response.parsed_body.fetch("direction")
    assert_equal 2, response.parsed_body.dig("counts", "imported")
  end

  private

  def get_token(scope)
    post "/ims/oneroster/v1p2/oauth/token",
      params: { grant_type: "client_credentials", scope: scope },
      headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("sis-consumer", "sis-consumer-secret") }
    assert_response :success
    response.parsed_body.fetch("access_token")
  end
end
