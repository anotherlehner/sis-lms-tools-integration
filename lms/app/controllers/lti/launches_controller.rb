module Lti
  class LaunchesController < ::ApplicationController
    before_action :load_section_context
    before_action :require_section_access

    def create
      activity = @course.activities.find(params[:id])
      return redirect_to course_section_path(@course, @section), alert: "This is not a tool activity." unless
        activity.activity_type == "tool"
      return redirect_to course_section_path(@course, @section), alert: "Student enrollment is required." unless
        @section.enrollments.exists?(user_id: current_user.id)

      login_hint = SecureRandom.urlsafe_base64(32)
      LtiLaunch.create!(
        activity: activity,
        section: @section,
        user: current_user,
        login_hint_digest: Digest::SHA256.hexdigest(login_hint),
        expires_at: 5.minutes.from_now
      )

      query = URI.encode_www_form(
        iss: Platform::ISSUER,
        client_id: Platform::CLIENT_ID,
        login_hint: login_hint,
        target_link_uri: Platform.tool_launch_url
      )
      redirect_to "#{Platform.tool_login_url}?#{query}", allow_other_host: true
    end
  end
end
