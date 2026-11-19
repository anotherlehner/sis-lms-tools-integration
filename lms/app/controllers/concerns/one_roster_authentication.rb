module OneRosterAuthentication
  extend ActiveSupport::Concern

  private

  def require_one_roster_scope(scope)
    token = request.authorization.to_s.match(/\ABearer\s+(.+)\z/i)&.captures&.first
    claims = token && Rails.application.message_verifier("one_roster_access_token")
      .verified(token, purpose: "oneroster-access")
    scopes = claims.is_a?(Hash) ? claims.fetch("scope", "").split : []

    return if scopes.include?(scope)

    render json: { error: "A valid bearer token with the required scope is required." },
      status: :unauthorized
  end

  def require_sync_control_token
    expected = ENV.fetch("SYNC_CONTROL_TOKEN", "")
    supplied = request.authorization.to_s.match(/\ABearer\s+(.+)\z/i)&.captures&.first

    if expected.empty? || supplied.nil? ||
        supplied.bytesize != expected.bytesize ||
        !ActiveSupport::SecurityUtils.secure_compare(supplied, expected)
      render json: { error: "A valid sync control token is required." }, status: :unauthorized
    end
  end

  def secure_credential_match?(supplied, expected)
    expected.present? && supplied.present? &&
      supplied.bytesize == expected.bytesize &&
      ActiveSupport::SecurityUtils.secure_compare(supplied, expected)
  end
end
