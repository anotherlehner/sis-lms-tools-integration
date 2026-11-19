class SectionGrade < ApplicationRecord
  before_validation :ensure_grade_sourced_ids, on: :create

  belongs_to :section
  belongs_to :user

  validates :user_id, uniqueness: { scope: :section_id }
  validates :midterm_grade, :final_grade, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validate :user_must_be_enrolled

  private

  def ensure_grade_sourced_ids
    self.midterm_sourced_id ||= SecureRandom.uuid
    self.final_sourced_id ||= SecureRandom.uuid
  end

  def user_must_be_enrolled
    errors.add(:user, "must be enrolled in the section") if section && user && !section.enrollments.exists?(user_id: user.id)
  end
end
