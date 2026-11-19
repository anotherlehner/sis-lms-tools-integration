class Api::Ims::Oneroster::V1p2::OauthTokensController < Api::BaseController
  include OneRosterAuthentication

  TOKEN_LIFETIME = 1.hour
  SUPPORTED_SCOPE = OneRoster::ROSTER_READONLY_SCOPE

  def create
    return render json: { error: "grant_type must be client_credentials." }, status: :bad_request unless params[:grant_type] == "client_credentials"

    client_id, client_secret = ActionController::HttpAuthentication::Basic.user_name_and_password(request)
    expected_client_id = ENV.fetch("ONEROSTER_CLIENT_ID", "")
    expected_client_secret = ENV.fetch("ONEROSTER_CLIENT_SECRET", "")
    if expected_client_id.empty? || expected_client_secret.empty?
      return render json: { error: "OneRoster client credentials are not configured." }, status: :service_unavailable
    end

    unless secure_credential_match?(client_id, expected_client_id) &&
        secure_credential_match?(client_secret, expected_client_secret)
      return render json: { error: "Invalid client credentials." }, status: :unauthorized
    end

    unless params[:scope].to_s.split == [SUPPORTED_SCOPE]
      return render json: { error: "The requested scope is not supported." }, status: :bad_request
    end

    token = Rails.application.message_verifier("one_roster_access_token").generate(
      { "client_id" => client_id, "scope" => SUPPORTED_SCOPE },
      purpose: "oneroster-access",
      expires_in: TOKEN_LIFETIME
    )
    render json: {
      access_token: token,
      token_type: "Bearer",
      expires_in: TOKEN_LIFETIME.to_i,
      scope: SUPPORTED_SCOPE
    }
  end
end
