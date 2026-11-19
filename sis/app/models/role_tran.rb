class RoleTran < ApplicationRecord
  has_many :roles, dependent: :restrict_with_error
  has_many :people, through: :roles

  validates :code, :name, :description, presence: true
  validates :code, uniqueness: true
end
