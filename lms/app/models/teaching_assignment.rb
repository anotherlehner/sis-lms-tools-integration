class TeachingAssignment < ApplicationRecord
  belongs_to :section
  belongs_to :user

  validates :user_id, uniqueness: { scope: :section_id }
  validate :user_must_be_an_instructor

  private

  def user_must_be_an_instructor
    errors.add(:user, "must have the instructor role") unless user&.instructor?
  end
end
