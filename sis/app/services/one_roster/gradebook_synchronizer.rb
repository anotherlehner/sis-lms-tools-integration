module OneRoster
  class GradebookSynchronizer
    def initialize(client: nil)
      @client = client || ApiClient.new(
        base_url: ENV.fetch("LMS_ONEROSTER_URL", "http://127.0.0.1:3000"),
        client_id: ENV["LMS_ONEROSTER_CLIENT_ID"],
        client_secret: ENV["LMS_ONEROSTER_CLIENT_SECRET"],
        scope: GRADEBOOK_READONLY_SCOPE
      )
    end

    def call
      line_items = unique_sourced_id_index(@client.fetch_collection("lineItems"), "lineItems")
      results = @client.fetch_collection("results")
      unique_sourced_id_index(results, "results")
      validate_active_records(line_items.values, "lineItems")
      validate_active_records(results, "results")
      counts = { imported: 0, skipped_unknown_students: 0 }

      ActiveRecord::Base.transaction do
        results.each do |result|
          student_id = required_reference(result, "student")
          person = Person.find_by(one_roster_sourced_id: student_id)
          unless person
            counts[:skipped_unknown_students] += 1
            next
          end

          line_item_id = required_reference(result, "lineItem")
          line_item = line_items[line_item_id]
          raise SyncError, "OneRoster result references unknown line item #{line_item_id}." unless line_item

          sync_result(person, line_item, result)
          counts[:imported] += 1
        end
      end

      counts
    rescue ActiveRecord::RecordInvalid => error
      raise SyncError, "Gradebook data could not be saved: #{error.record.errors.full_messages.to_sentence}"
    end

    private

    def sync_result(person, line_item, result)
      class_id = required_reference(line_item, "class")
      section = Section.find_by(one_roster_sourced_id: class_id)
      raise SyncError, "OneRoster line item references unknown class #{class_id}." unless section

      enrollment = Enrollment.find_by(person: person, section: section)
      raise SyncError, "OneRoster result has no SIS enrollment for student #{person.one_roster_sourced_id} in class #{class_id}." unless enrollment

      score = parse_score(result["score"])
      extensions = line_item.dig("metadata", "extensions") || {}
      grade_type = extensions["gradeType"]
      result_sourced_id = required(result, "sourcedId")

      if extensions["sourceType"] == "section_grade" && %w[midterm final].include?(grade_type)
        enrollment.update!(
          "#{grade_type}_grade" => score.to_s("F"),
          "#{grade_type}_result_sourced_id" => result_sourced_id
        )
      else
        sourced_id = required(line_item, "sourcedId")
        grade = Grade.find_or_initialize_by(enrollment: enrollment, activity_identifier: sourced_id)
        grade.assign_attributes(
          one_roster_sourced_id: result_sourced_id,
          activity_name: required(line_item, "title"),
          value: score.to_s("F"),
          comment: result["comment"]
        )
        grade.save!
      end
    end

    def parse_score(value)
      score = BigDecimal(value.to_s)
      raise SyncError, "OneRoster result score must be between 0 and 100." unless score.finite? && score.between?(0, 100)

      score
    rescue ArgumentError
      raise SyncError, "OneRoster result has an invalid score."
    end

    def required(record, key)
      raise SyncError, "OneRoster collection contains an invalid record." unless record.is_a?(Hash)

      value = record[key]
      raise SyncError, "OneRoster record is missing #{key}." unless value.is_a?(String) && value.present?

      value
    end

    def required_reference(record, key)
      reference = record[key]
      sourced_id = reference["sourcedId"] if reference.is_a?(Hash)
      raise SyncError, "OneRoster record has an invalid #{key} reference." unless sourced_id.is_a?(String) && sourced_id.present?

      sourced_id
    end

    def unique_sourced_id_index(records, collection_name)
      records.each_with_object({}) do |record, index|
        sourced_id = required(record, "sourcedId")
        raise SyncError, "LMS provider returned duplicate sourcedIds in #{collection_name}." if index.key?(sourced_id)

        index[sourced_id] = record
      end
    end

    def validate_active_records(records, collection_name)
      records.each do |record|
        next if record["status"] == "active"

        raise SyncError, "LMS provider returned unsupported status #{record['status'].inspect} in #{collection_name}."
      end
    end
  end
end
