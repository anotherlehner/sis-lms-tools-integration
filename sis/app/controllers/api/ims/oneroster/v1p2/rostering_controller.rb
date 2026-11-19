class Api::Ims::Oneroster::V1p2::RosteringController < Api::BaseController
  include OneRosterAuthentication

  before_action -> { require_one_roster_scope(OneRoster::ROSTER_READONLY_SCOPE) }

  def organizations
    render_collection(:orgs, payloads.organizations)
  end

  def courses
    render_collection(:courses, payloads.courses)
  end

  def classes
    render_collection(:classes, payloads.classes)
  end

  def users
    render_collection(:users, payloads.users)
  end

  def enrollments
    render_collection(:enrollments, payloads.enrollments)
  end

  private

  def payloads
    @payloads ||= OneRoster::RosterPayloads.new
  end

  def render_collection(name, records)
    limit = Integer(params.fetch(:limit, 100).to_s, 10)
    offset = Integer(params.fetch(:offset, 0).to_s, 10)
    return render(json: { error: "limit must be between 1 and 1000 and offset must be non-negative." }, status: :bad_request) unless limit.between?(1, 1000) && offset >= 0

    render json: { name => records.drop(offset).first(limit) }
  rescue ArgumentError
    render json: { error: "limit and offset must be integers." }, status: :bad_request
  end
end
