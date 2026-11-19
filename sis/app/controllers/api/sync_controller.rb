class Api::SyncController < Api::BaseController
  include OneRosterAuthentication

  before_action :require_sync_control_token

  def gradebook
    counts = OneRoster::GradebookSynchronizer.new.call
    render json: { status: "completed", direction: "lms_to_sis", counts: counts }
  rescue OneRoster::SyncError => error
    render json: { status: "failed", error: error.message }, status: :bad_gateway
  end
end
