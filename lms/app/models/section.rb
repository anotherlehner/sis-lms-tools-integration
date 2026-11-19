class Section < ApplicationRecord
  include OneRosterSourced

  belongs_to :course
  has_many :enrollments, dependent: :destroy
  has_many :students, through: :enrollments, source: :user
  has_many :teaching_assignments, dependent: :destroy
  has_many :instructors, through: :teaching_assignments, source: :user
  has_many :section_grades, dependent: :destroy

  validates :name, presence: true
end
