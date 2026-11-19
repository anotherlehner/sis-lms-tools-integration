class Grade < ApplicationRecord
  include OneRosterSourced

  belongs_to :enrollment

  validates :activity_name, :value, presence: true
end
