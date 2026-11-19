require "test_helper"
require "minitest/mock"
require "net/http"

class OneRoster::ApiClientTest < ActiveSupport::TestCase
  class FakeHttp
    attr_reader :requests

    def initialize(responses)
      @responses = responses
      @requests = []
    end

    def request(request)
      @requests << request
      code, body = @responses.shift
      response_class = code == 200 ? Net::HTTPOK : Net::HTTPUnauthorized
      response = response_class.new("1.1", code.to_s, "")
      response.instance_variable_set(:@body, body)
      response.instance_variable_set(:@read, true)
      response
    end
  end

  test "authenticates, follows pagination, and validates the token scope" do
    entries = Array.new(OneRoster::ApiClient::PAGE_SIZE) { |index| { "id" => index } }
    http = FakeHttp.new([
      [200, token_response],
      [200, JSON.generate("lineItems" => entries)],
      [200, JSON.generate("lineItems" => [{ "id" => 100 }, { "id" => 101 }])]
    ])
    client = build_client

    result = Net::HTTP.stub(:start, start_http(http)) { client.fetch_collection("lineItems") }

    assert_equal 102, result.length
    assert_equal ["/ims/oneroster/v1p2/oauth/token", "/ims/oneroster/v1p2/lineItems", "/ims/oneroster/v1p2/lineItems"], http.requests.map { |request| request.uri.path }
    assert_equal ["limit=100&offset=0", "limit=100&offset=100"], http.requests.drop(1).map { |request| request.uri.query }
    assert_match(/\ABasic /, http.requests.first["Authorization"])
    assert_equal "Bearer access-token", http.requests[1]["Authorization"]
  end

  test "surfaces provider HTTP failures" do
    http = FakeHttp.new([[401, JSON.generate("error" => "unauthorized")]])

    error = Net::HTTP.stub(:start, start_http(http)) do
      assert_raises(OneRoster::ApiClient::RemoteError) { build_client.fetch_collection("courses") }
    end
    assert_match "HTTP 401", error.message
  end

  private

  def build_client
    OneRoster::ApiClient.new(
      base_url: "http://provider.example",
      client_id: "consumer",
      client_secret: "consumer-secret",
      scope: OneRoster::ROSTER_READONLY_SCOPE
    )
  end

  def token_response
    JSON.generate(
      access_token: "access-token",
      token_type: "Bearer",
      scope: OneRoster::ROSTER_READONLY_SCOPE
    )
  end

  def start_http(http)
    ->(*_args, **_options, &block) { block.call(http) }
  end
end
