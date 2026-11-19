class ActivityCompletion < ApplicationRecord
  include OneRosterSourced

  belongs_to :activity
  belongs_to :user

  validates :user_id, uniqueness: { scope: :activity_id }
  validates :score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
end
