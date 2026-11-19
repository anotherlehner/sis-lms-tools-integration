require "test_helper"

class InstructorTest < ActiveSupport::TestCase
  test "prevents duplicate section assignment" do
    course = Course.create!(code: "COURSE-4", title: "Course Four")
    section = Section.create!(course: course, code: "01", title: "Section One")
    person = Person.create!(first_name: "Faculty", last_name: "Person", username: "faculty-test", password: "test")
    Instructor.create!(person: person, section: section)
    duplicate = Instructor.new(person: person, section: section)

    assert_not duplicate.valid?
  end
  # test "the truth" do
  #   assert true
  # end
end
