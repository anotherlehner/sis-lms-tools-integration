require "json"
require "net/http"
require "openssl"
require "uri"

module OneRoster
  class ApiClient
    PAGE_SIZE = 100
    TOKEN_PATH = "/ims/oneroster/v1p2/oauth/token"

    class RemoteError < SyncError
    end

    def initialize(base_url:, client_id:, client_secret:, scope:)
      @base_url = base_url.to_s.sub(%r{/\z}, "")
      @client_id = client_id
      @client_secret = client_secret
      @scope = scope
      raise RemoteError, "OneRoster provider URL and client credentials must be configured." if [@base_url, @client_id, @client_secret].any?(&:blank?)

      uri = URI.parse(@base_url)
      raise RemoteError, "OneRoster provider URL must use HTTP or HTTPS and include a host." unless uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      raise RemoteError, "OneRoster provider URL is invalid."
    end

    def fetch_collection(name)
      records = []
      offset = 0

      loop do
        response = get("/ims/oneroster/v1p2/#{name}?limit=#{PAGE_SIZE}&offset=#{offset}")
        raise RemoteError, "OneRoster provider returned an invalid response for #{name}." unless response.is_a?(Hash)

        items = response[name]
        raise RemoteError, "OneRoster provider response is missing the #{name} collection." unless items.is_a?(Array)

        records.concat(items)
        break if items.length < PAGE_SIZE

        offset += PAGE_SIZE
      end

      records
    end

    private

    def get(path)
      request = Net::HTTP::Get.new(URI("#{@base_url}#{path}"))
      request["Authorization"] = "Bearer #{access_token}"
      request["Accept"] = "application/json"
      perform(request, path)
    end

    def access_token
      return @access_token if @access_token

      uri = URI("#{@base_url}#{TOKEN_PATH}")
      request = Net::HTTP::Post.new(uri)
      request.basic_auth(@client_id, @client_secret)
      request.set_form_data(grant_type: "client_credentials", scope: @scope)
      request["Accept"] = "application/json"
      response = perform(request, TOKEN_PATH)
      raise RemoteError, "OneRoster token response is invalid." unless response.is_a?(Hash)

      token = response["access_token"]
      raise RemoteError, "OneRoster token response did not contain an access token." unless token.is_a?(String) && token.present?
      raise RemoteError, "OneRoster token response has an invalid token type." unless response["token_type"].to_s.casecmp("bearer").zero?
      raise RemoteError, "OneRoster token response did not grant the requested scope." unless response["scope"].to_s.split.include?(@scope)

      @access_token = token
    end

    def perform(request, path)
      uri = request.uri
      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 5,
        read_timeout: 30
      ) { |http| http.request(request) }
      raise RemoteError, "OneRoster provider returned HTTP #{response.code} for #{path}." unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body.to_s)
    rescue JSON::ParserError, URI::InvalidURIError
      raise RemoteError, "OneRoster provider returned invalid JSON for #{path}."
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, OpenSSL::SSL::SSLError => error
      raise RemoteError, "Unable to reach OneRoster provider for #{path}: #{error.class}."
    end
  end
end
