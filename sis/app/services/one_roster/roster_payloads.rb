module OneRoster
  class RosterPayloads
    ORGANIZATION_ID = "00000000-0000-4000-8000-000000000001"
    ORGANIZATION_LAST_MODIFIED = "1970-01-01T00:00:00Z"

    def organizations
      [{
        "sourcedId" => ORGANIZATION_ID,
        "status" => "active",
        "dateLastModified" => ORGANIZATION_LAST_MODIFIED,
        "name" => "Default School",
        "type" => "school",
        "identifier" => "default-school"
      }]
    end

    def courses
      Course.includes(:sections).order(:id).map do |course|
        base(course).merge(
          "title" => course.title,
          "description" => course.description,
          "courseCode" => course.code,
          "org" => reference(ORGANIZATION_ID)
        )
      end
    end

    def classes
      Section.includes(:course).order(:id).map do |section|
        base(section).merge(
          "title" => section.title,
          "classCode" => section.code,
          "course" => reference(section.course.one_roster_sourced_id),
          "school" => reference(ORGANIZATION_ID),
          "terms" => []
        )
      end
    end

    def users
      Person.includes(:role_trans).order(:id).filter_map do |person|
        role_codes = person.role_trans.map(&:code)
        role = %w[student instructor].find { |code| role_codes.include?(code) }
        role = role_for(role)
        next unless role

        payload = base(person).merge(
          "username" => person.username,
          "enabledUser" => true,
          "givenName" => person.first_name,
          "familyName" => person.last_name,
          "role" => role,
          "orgs" => [reference(ORGANIZATION_ID)]
        )
        payload["userIds"] = [{ "type" => "identifier", "identifier" => person.identifier }] if person.identifier.present?
        payload
      end
    end

    def enrollments
      students = Enrollment.includes(:person, section: :course).order(:id).map do |enrollment|
        enrollment_payload(enrollment, "student")
      end
      teachers = Instructor.includes(:person, section: :course).order(:id).map do |assignment|
        enrollment_payload(assignment, "teacher")
      end
      students + teachers
    end

    private

    def enrollment_payload(assignment, role)
      section = assignment.section
      {
        "sourcedId" => assignment.one_roster_sourced_id,
        "status" => "active",
        "dateLastModified" => assignment.updated_at.utc.iso8601,
        "role" => role,
        "primary" => true,
        "user" => reference(assignment.person.one_roster_sourced_id),
        "class" => reference(section.one_roster_sourced_id),
        "school" => reference(ORGANIZATION_ID)
      }
    end

    def base(record)
      {
        "sourcedId" => record.one_roster_sourced_id,
        "status" => "active",
        "dateLastModified" => record.updated_at.utc.iso8601
      }
    end

    def reference(sourced_id)
      { "sourcedId" => sourced_id }
    end

    def role_for(code)
      { "student" => "student", "instructor" => "teacher" }[code]
    end
  end
end
