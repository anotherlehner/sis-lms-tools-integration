module Lti
  class OauthController < ApplicationController
    def create
      return render_oauth_error("unsupported_grant_type", status: :bad_request) unless
        params[:grant_type] == "client_credentials" &&
        params[:client_assertion_type] == "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"

      payload, header = decode_client_assertion(params[:client_assertion])
      return render_oauth_error("invalid_scope", status: :bad_request) unless
        params[:scope].to_s.split == [Platform::AGS_SCORE_SCOPE]

      token_value = SecureRandom.urlsafe_base64(32)
      LtiAccessToken.where("expires_at <= ?", Time.current).delete_all
      token = LtiAccessToken.create!(
        token_digest: Digest::SHA256.hexdigest(token_value),
        assertion_jti: payload.fetch("jti"),
        client_id: payload.fetch("iss"),
        scope: params[:scope],
        expires_at: 5.minutes.from_now
      )

      render json: {
        access_token: token_value,
        token_type: "Bearer",
        expires_in: (token.expires_at - Time.current).to_i,
        scope: token.scope
      }
    rescue JWT::DecodeError, KeyError, ArgumentError, ActiveRecord::RecordNotUnique
      render_oauth_error("invalid_client", status: :unauthorized)
    end

    private

    def decode_client_assertion(assertion)
      _unverified_payload, unverified_header = JWT.decode(assertion.to_s, nil, false)
      kid = unverified_header["kid"]
      key = Platform.tool_public_key(kid)
      payload, header = JWT.decode(assertion, key, true, algorithms: ["RS256"])
      now = Time.current.to_i
      raise JWT::DecodeError, "Invalid assertion issuer." unless payload["iss"] == Platform::CLIENT_ID
      raise JWT::DecodeError, "Invalid assertion subject." unless payload["sub"] == Platform::CLIENT_ID
      raise JWT::DecodeError, "Invalid assertion audience." unless payload["aud"] == Platform.token_endpoint
      raise JWT::DecodeError, "Invalid assertion expiry." unless payload["exp"].is_a?(Integer) &&
        payload["exp"] > now && payload["exp"] <= now + 300
      raise JWT::DecodeError, "Invalid assertion time." unless payload["iat"].is_a?(Integer) &&
        payload["iat"] <= now + 30 && payload["iat"] >= now - 300
      raise JWT::DecodeError, "Missing assertion identifier." unless payload["jti"].is_a?(String) &&
        payload["jti"].present? && payload["jti"].length <= 128
      raise JWT::DecodeError, "Unexpected signing key." unless header["kid"] == kid

      [payload, header]
    rescue JWT::DecodeError
      raise
    rescue KeyError, ArgumentError => error
      raise JWT::DecodeError, "Invalid client assertion: #{error.message}"
    end
  end
end
