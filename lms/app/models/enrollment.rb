class Enrollment < ApplicationRecord
  include OneRosterSourced

  belongs_to :section
  belongs_to :user

  after_create :initialize_grades

  validates :user_id, uniqueness: { scope: :section_id }
  validate :user_must_be_a_student

  private

  def initialize_grades
    SectionGrade.find_or_create_by!(section: section, user: user)
    section.course.activities.find_each do |activity|
      ActivityCompletion.find_or_create_by!(activity: activity, user: user)
    end
  end

  def user_must_be_a_student
    errors.add(:user, "must have the student role") unless user&.student?
  end
end
