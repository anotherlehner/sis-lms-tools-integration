module OneRosterSourced
  extend ActiveSupport::Concern

  included do
    before_validation :ensure_one_roster_sourced_id, on: :create
  end

  private

  def ensure_one_roster_sourced_id
    self.one_roster_sourced_id ||= SecureRandom.uuid
  end
end
