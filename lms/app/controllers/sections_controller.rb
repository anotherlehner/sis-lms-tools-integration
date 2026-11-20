class SectionsController < ApplicationController
  before_action :load_section_context
  before_action :require_section_access

  def show
    @activities = @course.activities
    @completions = current_user.activity_completions
      .where(activity_id: @activities.select(:id))
      .index_by(&:activity_id)
    @show_student_controls = current_user.admin? || @section.enrollments.exists?(user_id: current_user.id)
    @show_tool_launch = @section.enrollments.exists?(user_id: current_user.id)
    @show_instructor_controls = current_user.can_teach_section?(@section)
  end
end
