class GradebooksController < ApplicationController
  before_action :load_section_context
  before_action :require_section_instructor

  def show
    load_gradebook
  end

  def update
    failure_messages = []

    ActiveRecord::Base.transaction do
      params.fetch(:grades, {}).each do |user_id, attributes|
        student = @section.students.find(user_id)
        grade = @section.section_grades.find_or_initialize_by(user: student)
        unless grade.update(attributes.permit(:midterm_grade, :final_grade))
          failure_messages.concat(grade.errors.full_messages)
          raise ActiveRecord::Rollback
        end
      end

      params.fetch(:activity_grades, {}).each do |user_id, activity_grades|
        student = @section.students.find(user_id)
        activity_grades.each do |activity_id, attributes|
          activity = @course.activities.find(activity_id)
          completion = activity.activity_completions.find_or_initialize_by(user: student)
          unless completion.update(score: attributes.permit(:score)[:score])
            failure_messages.concat(completion.errors.full_messages)
            raise ActiveRecord::Rollback
          end
        end
      end
    end

    if failure_messages.any?
      @grade_errors = failure_messages.uniq
      load_gradebook
      render :show, status: :unprocessable_content
    else
      redirect_to course_section_gradebook_path(@course, @section), notice: "Grades saved."
    end
  end

  private

  def load_gradebook
    @students = @section.students.order(:last_name, :first_name)
    @activities = @course.activities
    @section_grades = @section.section_grades.index_by(&:user_id)
    @activity_completions = ActivityCompletion
      .where(user_id: @students.select(:id), activity_id: @activities.select(:id))
      .index_by { |completion| [completion.user_id, completion.activity_id] }
  end
end
