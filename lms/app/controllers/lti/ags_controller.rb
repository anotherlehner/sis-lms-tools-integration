module Lti
  class AgsController < ApplicationController
    def line_item
      return head :unauthorized unless bearer_access_token

      activity, section = find_line_item
      return head :not_found unless valid_line_item?(activity, section)

      render json: {
        id: line_item_url(activity, section),
        scoreMaximum: 100,
        label: activity.title,
        resourceId: activity.one_roster_sourced_id,
        tag: "acme-guess-the-number"
      }
    end

    def create_score
      return head :unauthorized unless bearer_access_token

      activity, section = find_line_item
      score = score_payload
      return head :unprocessable_content unless score.is_a?(Hash)

      user = User.find_by!(one_roster_sourced_id: score["userId"])
      attempt_count = attempt_count_from(score["comment"])
      score_given = Float(score["scoreGiven"])
      score_maximum = Float(score["scoreMaximum"])

      unless valid_line_item?(activity, section) &&
          section.enrollments.exists?(user_id: user.id) &&
          score_maximum == 100 &&
          score_given == 100 &&
          score["activityProgress"] == "Completed" &&
          score["gradingProgress"] == "FullyGraded" &&
          valid_timestamp?(score["timestamp"])
        return head :unprocessable_content
      end

      completion = activity.activity_completions.find_or_initialize_by(user: user)
      completion.update!(
        completed_at: completion.completed_at || Time.current,
        score: 100,
        attempt_count: attempt_count
      )

      head :no_content
    rescue ActiveRecord::RecordNotFound
      head :not_found
    rescue ArgumentError, KeyError, JSON::ParserError, TypeError
      head :unprocessable_content
    end

    private

    def score_payload
      if request.media_type == "application/vnd.ims.lis.v1.score+json"
        JSON.parse(request.raw_post)
      else
        request.request_parameters
      end
    end

    def find_line_item
      activity = Activity.find(params[:activity_id])
      section = Section.find(params[:section_id])
      [activity, section]
    end

    def valid_line_item?(activity, section)
      activity.tool? && activity.course_id == section.course_id
    end

    def valid_timestamp?(timestamp)
      return false unless timestamp.is_a?(String)

      Time.iso8601(timestamp)
      true
    rescue ArgumentError
      false
    end

    def attempt_count_from(comment)
      match = comment.to_s.match(/\ASolved in ([1-9]\d*) guesses?\z/)
      raise ArgumentError, "The AGS comment must include the guess count." unless match

      match[1].to_i
    end

    def line_item_url(activity, section)
      "#{Platform::ISSUER}/lti/ags/line_items/#{activity.id}/sections/#{section.id}"
    end
  end
end
