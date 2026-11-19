require "test_helper"

class GradeTest < ActiveSupport::TestCase
  test "requires activity name and value" do
    course = Course.create!(code: "COURSE-5", title: "Course Five")
    section = Section.create!(course: course, code: "01", title: "Section One")
    person = Person.create!(first_name: "Student", last_name: "Person", username: "grade-test", password: "test")
    enrollment = Enrollment.create!(person: person, section: section)

    assert_not Grade.new(enrollment: enrollment).valid?
    assert Grade.new(enrollment: enrollment, activity_name: "Quiz", value: "A").valid?
  end
  # test "the truth" do
  #   assert true
  # end
end
