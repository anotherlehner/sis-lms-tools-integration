class Course < ApplicationRecord
  has_many :sections, dependent: :destroy
  has_many :activities, -> { order(:position, :id) }, dependent: :destroy

  validates :title, presence: true
end
