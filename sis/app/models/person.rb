class Person < ApplicationRecord
  include OneRosterSourced

  has_many :roles, dependent: :destroy
  has_many :role_trans, through: :roles
  has_many :enrollments, dependent: :destroy
  has_many :sections, through: :enrollments
  has_many :instructor_assignments, class_name: "Instructor", dependent: :destroy
  has_many :taught_sections, through: :instructor_assignments, source: :section

  validates :first_name, :last_name, :username, :password, presence: true
  validates :username, uniqueness: true
  validates :identifier, uniqueness: true, allow_nil: true

  def admin?
    role_trans.exists?(code: "admin")
  end
end
