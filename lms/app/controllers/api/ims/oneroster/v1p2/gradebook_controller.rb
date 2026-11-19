class Api::Ims::Oneroster::V1p2::GradebookController < Api::BaseController
  include OneRosterAuthentication

  before_action -> { require_one_roster_scope(OneRoster::GRADEBOOK_READONLY_SCOPE) }

  def line_items
    render_collection(:lineItems, payloads.line_items)
  end

  def results
    render_collection(:results, payloads.results)
  end

  private

  def payloads
    @payloads ||= OneRoster::GradebookPayloads.new
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
