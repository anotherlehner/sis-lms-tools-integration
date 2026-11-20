class LtiLaunch < ApplicationRecord
  belongs_to :activity
  belongs_to :section
  belongs_to :user

  validates :login_hint_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true
end
