class Api::SyncController < Api::BaseController
  include OneRosterAuthentication

  before_action :require_sync_control_token

  def roster
    counts = OneRoster::RosterSynchronizer.new.call
    render json: { status: "completed", direction: "sis_to_lms", counts: counts }
  rescue OneRoster::SyncError => error
    render json: { status: "failed", error: error.message }, status: :bad_gateway
  end
end
