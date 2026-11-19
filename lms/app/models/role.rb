class Role < ApplicationRecord
  NAMES = %w[student admin instructor].freeze

  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  validates :name, inclusion: { in: NAMES }, uniqueness: true
end
