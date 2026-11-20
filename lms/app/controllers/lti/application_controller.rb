module Lti
  class ApplicationController < ::ApplicationController
    skip_before_action :require_login
    skip_forgery_protection

    private

    def bearer_access_token
      match = request.authorization.to_s.match(/\ABearer ([A-Za-z0-9_-]+)\z/)
      return unless match

      token = LtiAccessToken.find_by(token_digest: Digest::SHA256.hexdigest(match[1]))
      token if token&.active? && token.client_id == Platform::CLIENT_ID &&
        token.scope.split.include?(Platform::AGS_SCORE_SCOPE)
    end

    def render_oauth_error(error, status:)
      render json: { error: error }, status: status
    end
  end
end
