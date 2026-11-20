class User < ApplicationRecord
  include OneRosterSourced

  has_secure_password

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :enrollments, dependent: :destroy
  has_many :enrolled_sections, through: :enrollments, source: :section
  has_many :teaching_assignments, dependent: :destroy
  has_many :taught_sections, through: :teaching_assignments, source: :section
  has_many :activity_completions, dependent: :destroy
  has_many :section_grades, dependent: :destroy
  has_many :lti_launches, dependent: :delete_all

  before_validation :normalize_identity
  before_validation :set_default_password, on: :create

  validates :first_name, :last_name, :identifier, :username, presence: true
  validates :identifier, uniqueness: true
  validates :username, uniqueness: { case_sensitive: false }

  def full_name
    "#{first_name} #{last_name}"
  end

  def role_names
    roles.map(&:name).sort
  end

  def has_role?(name)
    roles.any? { |role| role.name == name.to_s }
  end

  def admin?
    has_role?(:admin)
  end

  def student?
    has_role?(:student)
  end

  def instructor?
    has_role?(:instructor)
  end

  def can_access_section?(section)
    admin? || enrolled_sections.exists?(id: section.id) || taught_sections.exists?(id: section.id)
  end

  def can_teach_section?(section)
    admin? || taught_sections.exists?(id: section.id)
  end

  private

  def normalize_identity
    self.identifier = identifier.to_s.strip
    self.username = username.to_s.strip.downcase
  end

  def set_default_password
    self.password = username if password.blank? && username.present?
  end
end
