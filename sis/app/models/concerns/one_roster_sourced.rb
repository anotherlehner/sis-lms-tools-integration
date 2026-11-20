module OneRosterSourced
  extend ActiveSupport::Concern

  # SIS records need a persistent OneRoster sourcedId to identify them in
  # provider responses and in references exchanged during sync.
  included do
    before_validation :ensure_one_roster_sourced_id, on: :create
  end

  private

  def ensure_one_roster_sourced_id
    self.one_roster_sourced_id ||= SecureRandom.uuid
  end
end
