module OneRoster
  class RosterSynchronizer
    ROLE_MAP = {
      "student" => "student",
      "teacher" => "instructor"
    }.freeze

    def initialize(client: nil)
      @client = client || ApiClient.new(
        base_url: ENV.fetch("SIS_ONEROSTER_URL", "http://127.0.0.1:3001"),
        client_id: ENV["SIS_ONEROSTER_CLIENT_ID"],
        client_secret: ENV["SIS_ONEROSTER_CLIENT_SECRET"],
        scope: ROSTER_READONLY_SCOPE
      )
    end

    def call
      organizations = @client.fetch_collection("orgs")
      courses = @client.fetch_collection("courses")
      classes = @client.fetch_collection("classes")
      users = @client.fetch_collection("users")
      enrollments = @client.fetch_collection("enrollments")

      raise SyncError, "SIS provider did not return an organization." if organizations.empty?
      {
        "users" => users,
        "courses" => courses,
        "classes" => classes,
        "enrollments" => enrollments
      }.each { |name, records| validate_unique_sourced_ids(records, name) }
      {
        "users" => users,
        "courses" => courses,
        "classes" => classes,
        "enrollments" => enrollments
      }.each { |name, records| validate_active_records(records, name) }

      counts = { users: 0, courses: 0, classes: 0, enrollments: 0 }
      ActiveRecord::Base.transaction do
        users.each { |record| sync_user(record); counts[:users] += 1 }
        courses.each { |record| sync_course(record); counts[:courses] += 1 }
        classes.each { |record| sync_class(record); counts[:classes] += 1 }
        enrollments.each { |record| sync_enrollment(record); counts[:enrollments] += 1 }
      end
      counts
    rescue ActiveRecord::RecordInvalid => error
      raise SyncError, "Roster data could not be saved: #{error.record.errors.full_messages.to_sentence}"
    end

    private

    def sync_user(record)
      sourced_id = required(record, "sourcedId")
      username = required(record, "username")
      password = optional_text(record, "password")
      if record.key?("password") && password.blank?
        raise SyncError, "OneRoster user #{sourced_id} has an invalid password."
      end
      user_ids = record["userIds"]
      raise SyncError, "OneRoster user #{sourced_id} has invalid userIds." unless user_ids.nil? || user_ids.is_a?(Array)

      identifier_entry = user_ids&.find { |item| item.is_a?(Hash) && item["type"] == "identifier" }
      identifier = identifier_entry&.fetch("identifier", nil)
      raise SyncError, "OneRoster user #{sourced_id} has an invalid identifier." if identifier_entry && !identifier.is_a?(String)
      role_name = ROLE_MAP[record["role"]]
      raise SyncError, "Unsupported OneRoster user role #{record['role'].inspect}." unless role_name
      raise SyncError, "OneRoster user #{sourced_id} is disabled." if record["enabledUser"] == false

      user = User.find_by(one_roster_sourced_id: sourced_id)
      user ||= User.find_by(identifier: identifier) if identifier.present?
      user ||= User.new(one_roster_sourced_id: sourced_id, password: SecureRandom.hex(32))
      user.assign_attributes(
        one_roster_sourced_id: sourced_id,
        first_name: required(record, "givenName"),
        last_name: required(record, "familyName"),
        identifier: identifier.presence || sourced_id,
        username: username
      )
      # DEMO ONLY: Apply the SIS password from OneRoster to LMS login credentials.
      # Do not transfer or set passwords this way in a production system.
      user.password = password if password.present?
      user.save!
      user.roles = [Role.find_or_create_by!(name: role_name)]
    end

    def sync_course(record)
      sourced_id = required(record, "sourcedId")
      course = Course.find_or_initialize_by(one_roster_sourced_id: sourced_id)
      course.assign_attributes(
        title: required(record, "title"),
        course_code: optional_text(record, "courseCode"),
        description: optional_text(record, "description").to_s
      )
      course.save!
    end

    def sync_class(record)
      sourced_id = required(record, "sourcedId")
      course_id = required_reference(record, "course")
      course = Course.find_by!(one_roster_sourced_id: course_id)
      section = Section.find_or_initialize_by(one_roster_sourced_id: sourced_id)
      section.assign_attributes(
        course: course,
        name: required(record, "title"),
        class_code: optional_text(record, "classCode")
      )
      section.save!
    rescue ActiveRecord::RecordNotFound
      raise SyncError, "OneRoster class #{sourced_id} references an unknown course."
    end

    def sync_enrollment(record)
      sourced_id = required(record, "sourcedId")
      role = record["role"]
      user_id = required_reference(record, "user")
      class_id = required_reference(record, "class")
      user = User.find_by!(one_roster_sourced_id: user_id)
      section = Section.find_by!(one_roster_sourced_id: class_id)

      case role
      when "student"
        enrollment = section.enrollments.find_or_initialize_by(user: user)
        enrollment.one_roster_sourced_id = sourced_id
        enrollment.save!
      when "teacher"
        instructor_role = Role.find_or_create_by!(name: "instructor")
        user.roles << instructor_role unless user.roles.exists?(instructor_role.id)
        assignment = section.teaching_assignments.find_or_initialize_by(user: user)
        assignment.one_roster_sourced_id = sourced_id
        assignment.save!
      else
        raise SyncError, "Unsupported OneRoster enrollment role #{role.inspect} for #{sourced_id}."
      end
    rescue ActiveRecord::RecordNotFound
      raise SyncError, "OneRoster enrollment #{sourced_id} references an unknown user or class."
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

    def validate_unique_sourced_ids(records, collection_name)
      sourced_ids = records.map { |record| required(record, "sourcedId") }
      raise SyncError, "SIS provider returned duplicate sourcedIds in #{collection_name}." unless sourced_ids.uniq.length == sourced_ids.length
    end

    def validate_active_records(records, collection_name)
      records.each do |record|
        next if record["status"] == "active"

        raise SyncError, "SIS provider returned unsupported status #{record['status'].inspect} in #{collection_name}."
      end
    end

    def optional_text(record, key)
      value = record[key]
      raise SyncError, "OneRoster field #{key} must be a string." unless value.nil? || value.is_a?(String)

      value
    end
  end
end
