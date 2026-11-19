class ApplicationController < ActionController::Base
  helper_method :current_person

  def require_admin
    return if current_person&.admin?

    redirect_to sis_login_path, alert: "Administrator login required"
  end

  private

  def current_person
    return @current_person if defined?(@current_person)

    @current_person = Person.find_by(id: session[:person_id])
  end
end
