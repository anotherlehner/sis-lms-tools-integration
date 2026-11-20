require "test_helper"

class OneRoster::RosterPayloadsTest < ActiveSupport::TestCase
  setup do
    @student_role = role_translation("student")
    @teacher_role = role_translation("instructor")
    @student = person("student", [@student_role])
    @teacher = person("teacher", [@teacher_role])
    @course = Course.create!(code: "HIST-101", title: "History", description: "A history course")
    @section = Section.create!(course: @course, code: "A", title: "Section A")
    Enrollment.create!(person: @student, section: @section)
    Instructor.create!(person: @teacher, section: @section)
  end

  test "serializes organizations, courses, classes, users, and both enrollment roles" do
    payloads = OneRoster::RosterPayloads.new

    org = payloads.organizations.first
    assert_equal OneRoster::RosterPayloads::ORGANIZATION_ID, org.fetch("sourcedId")
    assert_equal "school", org.fetch("type")

    course = payloads.courses.first
    assert_equal @course.one_roster_sourced_id, course.fetch("sourcedId")
    assert_equal "HIST-101", course.fetch("courseCode")
    assert_equal org.fetch("sourcedId"), course.dig("org", "sourcedId")

    school_class = payloads.classes.first
    assert_equal @section.one_roster_sourced_id, school_class.fetch("sourcedId")
    assert_equal @course.one_roster_sourced_id, school_class.dig("course", "sourcedId")

    users = payloads.users.index_by { |user| user.fetch("username") }
    assert_equal "student", users.fetch("student").fetch("role")
    assert_equal "teacher", users.fetch("teacher").fetch("role")
    assert_equal @student.identifier, users.fetch("student").dig("userIds", 0, "identifier")
    assert_equal @student.password, users.fetch("student").fetch("password")

    enrollments = payloads.enrollments
    assert_equal %w[student teacher], enrollments.map { |enrollment| enrollment.fetch("role") }.sort
    assert_equal [@section.one_roster_sourced_id], enrollments.map { |enrollment| enrollment.dig("class", "sourcedId") }.uniq
  end

  test "uses persistent sourced IDs across repeated serialization" do
    payloads = OneRoster::RosterPayloads.new

    assert_equal payloads.users, payloads.users
    assert_match(/\A[0-9a-f-]{36}\z/, @student.one_roster_sourced_id)
  end

  test "does not publish administrative or staff accounts as roster users" do
    admin_role = role_translation("admin")
    staff_role = role_translation("staff")
    person("admin", [admin_role])
    person("staff", [staff_role])

    usernames = OneRoster::RosterPayloads.new.users.map { |user| user.fetch("username") }
    assert_equal %w[student teacher], usernames.sort
  end

  private

  def role_translation(code)
    RoleTran.create!(code: code, name: code.capitalize, description: "#{code} role")
  end

  def person(username, role_translations)
    record = Person.create!(
      username: username,
      first_name: username.capitalize,
      last_name: "Test",
      identifier: "id-#{username}",
      password: "password"
    )
    role_translations.each { |translation| Role.create!(person: record, role_tran: translation) }
    record
  end
end
