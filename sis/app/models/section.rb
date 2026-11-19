class Section < ApplicationRecord
  include OneRosterSourced

  belongs_to :course
  has_many :enrollments, dependent: :destroy
  has_many :people, through: :enrollments
  has_many :instructors, dependent: :destroy
  has_many :faculty, through: :instructors, source: :person

  validates :code, :title, presence: true
  validates :code, uniqueness: { scope: :course_id }
end
