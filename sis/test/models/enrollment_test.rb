require "test_helper"

class EnrollmentTest < ActiveSupport::TestCase
  test "prevents duplicate enrollment" do
    course = Course.create!(code: "COURSE-3", title: "Course Three")
    section = Section.create!(course: course, code: "01", title: "Section One")
    person = Person.create!(first_name: "Student", last_name: "Person", username: "student-test", password: "test")
    Enrollment.create!(person: person, section: section)
    duplicate = Enrollment.new(person: person, section: section)

    assert_not duplicate.valid?
  end
  # test "the truth" do
  #   assert true
  # end
end
