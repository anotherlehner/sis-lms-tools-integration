class ApplicationController < ActionController::Base
  before_action :require_login

  helper_method :current_user

  private

  def current_user
    @current_user ||= User.includes(:roles).find_by(id: session[:user_id])
  end

  def require_login
    redirect_to lms_login_path, alert: "Please sign in." unless current_user
  end

  def load_section_context
    @course = Course.find(params[:course_id])
    @section = @course.sections.find(params[:section_id] || params[:id])
  end

  def require_section_access
    return if current_user.can_access_section?(@section)

    redirect_to root_path, alert: "You do not have access to that section."
  end

  def require_section_instructor
    return if current_user.can_teach_section?(@section)

    redirect_to root_path, alert: "Instructor access is required."
  end
end
