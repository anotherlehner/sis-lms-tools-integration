class Course < ApplicationRecord
  include OneRosterSourced

  has_many :sections, dependent: :destroy

  validates :code, :title, presence: true
  validates :code, uniqueness: true
end
