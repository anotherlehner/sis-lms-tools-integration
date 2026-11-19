require "test_helper"

class OneRoster::GradebookSynchronizerTest < ActiveSupport::TestCase
  class FakeClient
    def initialize(collections)
      @collections = collections
    end

    def fetch_collection(name)
      @collections.fetch(name)
    end
  end

  setup do
    student_role = RoleTran.create!(code: "student", name: "Student", description: "Student role")
    @person = Person.create!(
      username: "student",
      first_name: "Sam",
      last_name: "Student",
      identifier: "student-id",
      password: "password"
    )
    Role.create!(person: @person, role_tran: student_role)
    course = Course.create!(code: "SCI-101", title: "Science")
    @section = Section.create!(course: course, code: "A", title: "Section A")
    Enrollment.create!(person: @person, section: @section)
    @midterm = line_item("line-midterm", "Midterm Grade", "section_grade", "midterm")
    @activity = line_item("line-activity", "Lab", "activity", nil)
  end

  test "imports section and activity scores idempotently" do
    synchronizer = OneRoster::GradebookSynchronizer.new(client: client([
      result("result-midterm", "line-midterm", "90.5"),
      result("result-activity", "line-activity", "87")
    ]))

    assert_equal({ imported: 2, skipped_unknown_students: 0 }, synchronizer.call)
    assert_equal "90.5", @section.enrollments.first.reload.midterm_grade
    assert_equal "result-midterm", @section.enrollments.first.midterm_result_sourced_id
    grade = Grade.find_by!(enrollment: @section.enrollments.first, activity_identifier: "line-activity")
    assert_equal "Lab", grade.activity_name
    assert_equal "87.0", grade.value
    assert_equal "result-activity", grade.one_roster_sourced_id

    synchronizer.call
    assert_equal 1, Grade.where(activity_identifier: "line-activity").count
  end

  test "reports and skips results for students not in the SIS" do
    assert_equal(
      { imported: 0, skipped_unknown_students: 1 },
      OneRoster::GradebookSynchronizer.new(client: client([
        result("unmatched-result", "line-activity", "88", "unknown-person")
      ])).call
    )
    assert_empty Grade.all
  end

  test "rolls back the full import when a score is invalid" do
    synchronizer = OneRoster::GradebookSynchronizer.new(client: client([
      result("result-midterm", "line-midterm", "90"),
      result("result-invalid", "line-activity", "101")
    ]))

    error = assert_raises(OneRoster::SyncError) { synchronizer.call }
    assert_match "between 0 and 100", error.message
    assert_nil @section.enrollments.first.reload.midterm_grade
    assert_empty Grade.all
  end

  test "rejects a result whose line item is absent" do
    synchronizer = OneRoster::GradebookSynchronizer.new(client: client([
      result("result-unknown-line", "missing-line-item", "80")
    ]))

    assert_raises(OneRoster::SyncError) { synchronizer.call }
    assert_empty Grade.all
  end

  test "rejects duplicate line item sourced IDs" do
    duplicate_line_item = @activity.merge("title" => "Duplicate")
    synchronizer = OneRoster::GradebookSynchronizer.new(
      client: FakeClient.new("lineItems" => [@midterm, @activity, duplicate_line_item], "results" => [])
    )

    error = assert_raises(OneRoster::SyncError) { synchronizer.call }
    assert_match "duplicate sourcedIds", error.message
  end

  test "rejects a result with an unsupported status" do
    result = self.result("result-deleted", "line-activity", "88").merge("status" => "tobedeleted")

    error = assert_raises(OneRoster::SyncError) do
      OneRoster::GradebookSynchronizer.new(client: client([result])).call
    end
    assert_match "unsupported status", error.message
    assert_empty Grade.all
  end

  private

  def line_item(id, title, source_type, grade_type)
    extensions = { "sourceType" => source_type }
    extensions["gradeType"] = grade_type if grade_type
    {
      "sourcedId" => id,
      "status" => "active",
      "title" => title,
      "class" => { "sourcedId" => @section.one_roster_sourced_id },
      "metadata" => { "extensions" => extensions }
    }
  end

  def result(id, line_item_id, score, student_id = @person.one_roster_sourced_id)
    {
      "sourcedId" => id,
      "status" => "active",
      "lineItem" => { "sourcedId" => line_item_id },
      "student" => { "sourcedId" => student_id },
      "score" => score
    }
  end

  def client(results)
    FakeClient.new(
      "lineItems" => [@midterm, @activity],
      "results" => results
    )
  end
end
