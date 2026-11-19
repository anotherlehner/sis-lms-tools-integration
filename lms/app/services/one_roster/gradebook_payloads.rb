module OneRoster
  class GradebookPayloads
    def line_items
      activity_items + section_grade_items
    end

    def results
      activity_results + section_grade_results
    end

    private

    def activity_items
      Activity.includes(course: :sections).order(:id).flat_map do |activity|
        activity.course.sections.map do |section|
          {
            "sourcedId" => activity_line_item_id(activity, section),
            "status" => "active",
            "dateLastModified" => activity.updated_at.utc.iso8601,
            "title" => activity.title,
            "class" => reference(section.one_roster_sourced_id),
            "resultValueMin" => 0,
            "resultValueMax" => 100,
            "metadata" => { "extensions" => { "sourceType" => "activity" } }
          }
        end
      end
    end

    def section_grade_items
      Section.includes(:section_grades).order(:id).flat_map do |section|
        %w[midterm final].map do |field|
          {
            "sourcedId" => section_grade_line_item_id(section, field),
            "status" => "active",
            "dateLastModified" => section.updated_at.utc.iso8601,
            "title" => "#{field.capitalize} Grade",
            "class" => reference(section.one_roster_sourced_id),
            "resultValueMin" => 0,
            "resultValueMax" => 100,
            "metadata" => { "extensions" => { "sourceType" => "section_grade", "gradeType" => field } }
          }
        end
      end
    end

    def activity_results
      ActivityCompletion.includes(:user, activity: { course: :sections }).where.not(score: nil).order(:id).flat_map do |completion|
        completion.activity.course.sections.filter_map do |section|
          next unless section.enrollments.exists?(user_id: completion.user_id)

          {
            "sourcedId" => Identifiers.uuid_v5(completion.one_roster_sourced_id, section.one_roster_sourced_id),
            "status" => "active",
            "dateLastModified" => completion.updated_at.utc.iso8601,
            "lineItem" => reference(activity_line_item_id(completion.activity, section)),
            "student" => reference(completion.user.one_roster_sourced_id),
            "score" => completion.score.to_f,
            "scoreDate" => completion.updated_at.utc.iso8601
          }
        end
      end
    end

    def section_grade_results
      SectionGrade.includes(:section, :user).order(:id).flat_map do |grade|
        %w[midterm final].filter_map do |field|
          score = grade.public_send("#{field}_grade")
          next if score.nil?

          {
            "sourcedId" => grade.public_send("#{field}_sourced_id"),
            "status" => "active",
            "dateLastModified" => grade.updated_at.utc.iso8601,
            "lineItem" => reference(section_grade_line_item_id(grade.section, field)),
            "student" => reference(grade.user.one_roster_sourced_id),
            "score" => score.to_f,
            "scoreDate" => grade.updated_at.utc.iso8601
          }
        end
      end
    end

    def activity_line_item_id(activity, section)
      Identifiers.uuid_v5(activity.one_roster_sourced_id, section.one_roster_sourced_id)
    end

    def section_grade_line_item_id(section, field)
      Identifiers.uuid_v5(section.one_roster_sourced_id, "section-grade:#{field}")
    end

    def reference(sourced_id)
      { "sourcedId" => sourced_id }
    end
  end
end
