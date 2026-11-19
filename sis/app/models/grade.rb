class Grade < ApplicationRecord
  belongs_to :enrollment

  validates :activity_name, :value, presence: true
end
