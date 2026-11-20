module Lti
  class PlatformController < ApplicationController
    def openid_configuration
      render json: {
        issuer: Platform::ISSUER,
        authorization_endpoint: Platform.authorization_endpoint,
        token_endpoint: Platform.token_endpoint,
        jwks_uri: Platform.jwks_uri,
        response_types_supported: ["id_token"],
        response_modes_supported: ["form_post"],
        subject_types_supported: ["public"],
        id_token_signing_alg_values_supported: ["RS256"],
        scopes_supported: ["openid"],
        token_endpoint_auth_methods_supported: ["private_key_jwt"],
        grant_types_supported: ["client_credentials"],
        "https://purl.imsglobal.org/spec/lti-platform-configuration" => {
          product_family_code: "simpl-lms",
          version: Rails.version,
          messages_supported: [{ type: "LtiResourceLinkRequest" }]
        }
      }
    end

    def jwks
      render json: { keys: [Platform.public_jwk] }
    end

    def authorize
      return head :bad_request unless valid_authorization_request?

      login_hint = params.require(:login_hint)
      login = LtiLaunch.find_by!(login_hint_digest: Digest::SHA256.hexdigest(login_hint))
      raise ActiveRecord::RecordNotFound if current_user && login.user_id != current_user.id
      raise ActiveRecord::RecordNotFound if login.used_at || login.expires_at <= Time.current
      raise ActiveRecord::RecordNotFound unless login.activity.tool? &&
        login.section.enrollments.exists?(user_id: login.user_id)

      login.with_lock do
        raise ActiveRecord::RecordNotFound if login.used_at || login.expires_at <= Time.current

        login.update!(used_at: Time.current)
      end

      render html: auto_post_form(Platform.tool_launch_url, id_token(login, params[:nonce]), params[:state]).html_safe
    rescue ActiveRecord::RecordNotFound, ActionController::ParameterMissing
      head :bad_request
    end

    private

    def valid_authorization_request?
      params[:client_id] == Platform::CLIENT_ID &&
        params[:redirect_uri] == Platform.tool_launch_url &&
        params[:response_type] == "id_token" &&
        params[:response_mode] == "form_post" &&
        params[:scope].to_s.split.include?("openid") &&
        params[:prompt] == "none" &&
        params[:state].present? && params[:state].length <= 512 &&
        params[:nonce].present? && params[:nonce].length <= 512
    end

    def id_token(login, nonce)
      now = Time.current.to_i
      section = login.section
      activity = login.activity
      user = login.user
      claims = {
        iss: Platform::ISSUER,
        aud: Platform::CLIENT_ID,
        sub: user.one_roster_sourced_id,
        iat: now,
        exp: now + 300,
        jti: SecureRandom.uuid,
        nonce: nonce,
        "https://purl.imsglobal.org/spec/lti/claim/deployment_id" => Platform::DEPLOYMENT_ID,
        "https://purl.imsglobal.org/spec/lti/claim/message_type" => "LtiResourceLinkRequest",
        "https://purl.imsglobal.org/spec/lti/claim/version" => "1.3.0",
        "https://purl.imsglobal.org/spec/lti/claim/target_link_uri" => Platform.tool_launch_url,
        "https://purl.imsglobal.org/spec/lti/claim/resource_link" => {
          id: activity.one_roster_sourced_id,
          title: activity.title
        },
        "https://purl.imsglobal.org/spec/lti/claim/context" => {
          id: section.one_roster_sourced_id,
          label: section.name,
          title: section.course.title
        },
        "https://purl.imsglobal.org/spec/lti/claim/roles" => [
          "http://purl.imsglobal.org/vocab/lis/v2/membership#Learner"
        ],
        "https://purl.imsglobal.org/spec/lti/claim/launch_presentation" => {
          document_target: "window",
          return_url: "#{Platform::ISSUER}#{Rails.application.routes.url_helpers.course_section_path(section.course, section)}"
        },
        "https://purl.imsglobal.org/spec/lti-ags/claim/endpoint" => {
          lineitem: ags_line_item_url(activity, section),
          scope: [Platform::AGS_SCORE_SCOPE]
        }
      }
      Platform.sign_id_token(claims)
    end

    def ags_line_item_url(activity, section)
      "#{Platform::ISSUER}/lti/ags/line_items/#{activity.id}/sections/#{section.id}"
    end

    def auto_post_form(action, id_token, state)
      <<~HTML
        <!doctype html>
        <html lang="en">
          <head><meta charset="utf-8"><title>Launching Acme tool</title></head>
          <body>
            <p>Launching Guess the Number…</p>
            <form id="lti-launch" method="post" action="#{ERB::Util.html_escape(action)}">
              <input type="hidden" name="id_token" value="#{ERB::Util.html_escape(id_token)}">
              <input type="hidden" name="state" value="#{ERB::Util.html_escape(state)}">
              <noscript><button type="submit">Continue to the tool</button></noscript>
            </form>
            <script>document.getElementById("lti-launch").submit()</script>
          </body>
        </html>
      HTML
    end
  end
end
