require "test_helper"

class OneRoster::RosterSynchronizerTest < ActiveSupport::TestCase
  class FakeClient
    def initialize(collections)
      @collections = collections
    end

    def fetch_collection(name)
      @collections.fetch(name)
    end
  end

  setup do
    @student_id = SecureRandom.uuid
    @teacher_id = SecureRandom.uuid
    @course_id = SecureRandom.uuid
    @class_id = SecureRandom.uuid
    @student_enrollment_id = SecureRandom.uuid
    @teacher_enrollment_id = SecureRandom.uuid
    @collections = {
      "orgs" => [{ "sourcedId" => SecureRandom.uuid, "status" => "active" }],
      "users" => [
        user(@student_id, "student", "student"),
        user(@teacher_id, "teacher", "teacher")
      ],
      "courses" => [{ "sourcedId" => @course_id, "status" => "active", "title" => "History", "courseCode" => "HIST-101", "description" => "Survey course" }],
      "classes" => [{
        "sourcedId" => @class_id,
        "status" => "active",
        "title" => "Section A",
        "classCode" => "A",
        "course" => { "sourcedId" => @course_id }
      }],
      "enrollments" => [
        enrollment(@student_enrollment_id, @student_id, "student"),
        enrollment(@teacher_enrollment_id, @teacher_id, "teacher")
      ]
    }
  end

  test "imports roster records idempotently and maps instructor assignments" do
    synchronizer = OneRoster::RosterSynchronizer.new(client: FakeClient.new(@collections))

    expected_counts = { users: 2, courses: 1, classes: 1, enrollments: 2 }
    assert_equal expected_counts, synchronizer.call
    assert_equal expected_counts, synchronizer.call

    student = User.find_by!(one_roster_sourced_id: @student_id)
    teacher = User.find_by!(one_roster_sourced_id: @teacher_id)
    section = Section.find_by!(one_roster_sourced_id: @class_id)
    assert student.student?
    assert teacher.instructor?
    assert_equal "Survey course", section.course.description
    assert_equal "HIST-101", section.course.course_code
    assert_equal "A", section.class_code
    assert_equal 1, section.enrollments.count
    assert_equal 1, section.teaching_assignments.count
    assert_equal @student_enrollment_id, section.enrollments.first.one_roster_sourced_id
    assert_equal @teacher_enrollment_id, section.teaching_assignments.first.one_roster_sourced_id
    refute student.authenticate("student")
  end

  test "rolls back all roster changes if a class references an unknown course" do
    @collections["classes"].first["course"]["sourcedId"] = SecureRandom.uuid

    assert_raises(OneRoster::SyncError) do
      OneRoster::RosterSynchronizer.new(client: FakeClient.new(@collections)).call
    end

    assert_empty User.all
    assert_empty Course.all
  end

  test "rejects roles not represented by the LMS" do
    @collections["users"].first["role"] = "aide"

    error = assert_raises(OneRoster::SyncError) do
      OneRoster::RosterSynchronizer.new(client: FakeClient.new(@collections)).call
    end
    assert_match "Unsupported OneRoster user role", error.message
    assert_empty User.all
  end

  test "does not grant LMS administrator access from an incoming administrator role" do
    @collections["users"].first["role"] = "administrator"

    error = assert_raises(OneRoster::SyncError) do
      OneRoster::RosterSynchronizer.new(client: FakeClient.new(@collections)).call
    end
    assert_match "Unsupported OneRoster user role", error.message
    assert_empty User.all
  end

  test "rejects duplicate sourced IDs before applying records" do
    @collections["users"] << @collections["users"].first.dup

    error = assert_raises(OneRoster::SyncError) do
      OneRoster::RosterSynchronizer.new(client: FakeClient.new(@collections)).call
    end
    assert_match "duplicate sourcedIds", error.message
    assert_empty User.all
  end

  test "rejects unsupported record status without changing the LMS" do
    @collections["courses"].first["status"] = "tobedeleted"

    error = assert_raises(OneRoster::SyncError) do
      OneRoster::RosterSynchronizer.new(client: FakeClient.new(@collections)).call
    end
    assert_match "unsupported status", error.message
    assert_empty User.all
  end

  private

  def user(sourced_id, username, role)
    {
      "sourcedId" => sourced_id,
      "status" => "active",
      "username" => username,
      "givenName" => username.capitalize,
      "familyName" => "Test",
      "role" => role,
      "enabledUser" => true,
      "userIds" => [{ "type" => "identifier", "identifier" => "sis-#{username}" }]
    }
  end

  def enrollment(sourced_id, user_id, role)
    {
      "sourcedId" => sourced_id,
      "status" => "active",
      "role" => role,
      "user" => { "sourcedId" => user_id },
      "class" => { "sourcedId" => @class_id }
    }
  end
end
