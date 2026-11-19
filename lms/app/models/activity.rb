class Activity < ApplicationRecord
  TYPES = %w[custom_content tool].freeze

  belongs_to :course
  has_many :activity_completions, dependent: :destroy

  after_create :initialize_student_completions

  validates :title, presence: true
  validates :activity_type, inclusion: { in: TYPES }

  def custom_content?
    activity_type == "custom_content"
  end

  private

  def initialize_student_completions
    course.sections.joins(:enrollments).distinct.find_each do |section|
      section.students.find_each do |student|
        activity_completions.find_or_create_by!(user: student)
      end
    end
  end
end
