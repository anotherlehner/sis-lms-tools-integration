require "test_helper"

class OneRoster::GradebookPayloadsTest < ActiveSupport::TestCase
  setup do
    student_role = Role.create!(name: "student")
    student = User.create!(
      first_name: "Sam",
      last_name: "Student",
      identifier: "student-id",
      username: "student",
      password: "password"
    )
    student.roles << student_role
    course = Course.create!(title: "Science")
    @section = Section.create!(course: course, name: "Section A")
    Enrollment.create!(section: @section, user: student)
    @activity = Activity.create!(course: course, title: "Lab")
    @activity.activity_completions.find_by!(user: student).update!(score: 93)
    grade = SectionGrade.find_by!(section: @section, user: student)
    grade.update!(midterm_grade: 88, final_grade: 91)
  end

  test "publishes unique line items and results for activities and section grades" do
    payloads = OneRoster::GradebookPayloads.new
    line_items = payloads.line_items
    results = payloads.results

    assert_equal 3, line_items.length
    assert_equal 3, results.length
    assert_equal line_items.length, line_items.map { |item| item.fetch("sourcedId") }.uniq.length
    assert_equal results.length, results.map { |result| result.fetch("sourcedId") }.uniq.length
    assert_equal [@section.one_roster_sourced_id], line_items.map { |item| item.dig("class", "sourcedId") }.uniq
    assert_equal %w[final midterm], line_items.filter_map { |item| item.dig("metadata", "extensions", "gradeType") }.sort
    assert_equal [88.0, 91.0, 93.0], results.map { |result| result.fetch("score") }.sort
  end

  test "derives stable UUID line item identifiers" do
    payloads = OneRoster::GradebookPayloads.new

    first_ids = payloads.line_items.map { |item| item.fetch("sourcedId") }
    second_ids = payloads.line_items.map { |item| item.fetch("sourcedId") }
    assert_equal first_ids, second_ids
    first_ids.each { |id| assert_match(/\A[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}\z/, id) }
  end
end
