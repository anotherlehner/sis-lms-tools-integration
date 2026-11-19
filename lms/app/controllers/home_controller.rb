class HomeController < ApplicationController
  def show
    @student_sections = current_user.enrolled_sections.includes(:course).order(:id)
    @teaching_sections = current_user.taught_sections.includes(:course).order(:id)
    @all_sections = Section.includes(:course).order(:id) if current_user.admin?
  end
end
