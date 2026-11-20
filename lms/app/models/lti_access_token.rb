class LtiAccessToken < ApplicationRecord
  validates :token_digest, :assertion_jti, :client_id, :scope, :expires_at, presence: true
  validates :token_digest, :assertion_jti, uniqueness: true

  def active?
    expires_at.future?
  end
end
