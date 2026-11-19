class ActivitiesController < ApplicationController
  before_action :load_section_context
  before_action :require_section_access
  before_action :require_section_instructor, except: :complete
  before_action :load_activity, only: %i[update destroy complete]

  def create
    activity = @course.activities.build(activity_params.merge(activity_type: "custom_content"))

    if activity.save
      redirect_to course_section_path(@course, @section), notice: "Activity added."
    else
      redirect_to course_section_path(@course, @section), alert: activity.errors.full_messages.to_sentence
    end
  end

  def update
    if @activity.custom_content? && @activity.update(activity_params)
      redirect_to course_section_path(@course, @section), notice: "Activity updated."
    else
      message = @activity.errors.full_messages.to_sentence.presence || "Only custom content activities can be edited here."
      redirect_to course_section_path(@course, @section), alert: message
    end
  end

  def destroy
    if @activity.custom_content?
      @activity.destroy!
      redirect_to course_section_path(@course, @section), notice: "Activity removed."
    else
      redirect_to course_section_path(@course, @section), alert: "Tool activities are not available in Phase 1."
    end
  end

  def complete
    unless current_user.admin? || @section.enrollments.exists?(user_id: current_user.id)
      redirect_to root_path, alert: "Student access to this section is required."
      return
    end

    completion = @activity.activity_completions.find_or_initialize_by(user: current_user)
    if completion.update(completed_at: Time.current)
      redirect_to course_section_path(@course, @section), notice: "Activity marked complete."
    else
      redirect_to course_section_path(@course, @section), alert: completion.errors.full_messages.to_sentence
    end
  end

  private

  def load_activity
    @activity = @course.activities.find(params[:id])
  end

  def activity_params
    params.require(:activity).permit(:title, :content, :position)
  end
end
