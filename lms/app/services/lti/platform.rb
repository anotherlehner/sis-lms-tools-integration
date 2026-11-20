require "net/http"

module Lti
  class Platform
    AGS_SCORE_SCOPE = "https://purl.imsglobal.org/spec/lti-ags/scope/score"
    CLIENT_ID = ENV.fetch("LTI_TOOL_CLIENT_ID", "acme-guess-the-number")
    DEPLOYMENT_ID = ENV.fetch("LTI_DEPLOYMENT_ID", "local-acme")
    ISSUER = ENV.fetch("LTI_PLATFORM_ISSUER", "http://127.0.0.1:3000").delete_suffix("/")
    TOOL_BASE_URL = ENV.fetch("LTI_TOOL_BASE_URL", "http://127.0.0.1:3002").delete_suffix("/")
    KEY_ID = "lms-platform-key"
    TOOL_KEY_ID = "acme-tool-key"

    def self.authorization_endpoint
      "#{ISSUER}/lti/authorize"
    end

    def self.token_endpoint
      "#{ISSUER}/lti/oauth/token"
    end

    def self.jwks_uri
      "#{ISSUER}/lti/jwks"
    end

    def self.tool_login_url
      "#{TOOL_BASE_URL}/lti/login"
    end

    def self.tool_launch_url
      "#{TOOL_BASE_URL}/lti/launch"
    end

    def self.tool_jwks_uri
      "#{TOOL_BASE_URL}/.well-known/jwks.json"
    end

    def self.private_key
      @private_key ||= if Rails.env.test?
        OpenSSL::PKey::RSA.generate(2048)
      else
        default_path = Rails.root.join("../.local/lti/platform.pem").expand_path.to_s
        path = ENV.fetch("LTI_PLATFORM_PRIVATE_KEY_PATH", default_path)
        raise "LTI platform key is missing at #{path}; run ./dev start to generate local keys." unless File.file?(path)

        OpenSSL::PKey::RSA.new(File.read(path))
      end
    end

    def self.public_jwk
      JWT::JWK.new(private_key, kid: KEY_ID).export.merge(use: "sig", alg: "RS256")
    end

    def self.sign_id_token(claims)
      JWT.encode(claims, private_key, "RS256", { kid: KEY_ID })
    end

    def self.tool_public_key(kid)
      uri = URI(tool_jwks_uri)
      response = Net::HTTP.start(uri.host, uri.port, open_timeout: 2, read_timeout: 2) do |http|
        http.get(uri.request_uri)
      end
      raise "Tool JWKS endpoint returned HTTP #{response.code}." unless response.is_a?(Net::HTTPSuccess)

      jwk = JSON.parse(response.body).fetch("keys").find do |key|
        key["kid"] == kid && key["kty"] == "RSA" && key["use"] == "sig"
      end
      raise JWT::DecodeError, "Unknown tool signing key." unless jwk

      JWT::JWK.import(jwk).public_key
    rescue JSON::ParserError, KeyError => error
      raise JWT::DecodeError, "Invalid tool JWKS: #{error.message}"
    end
  end
end
