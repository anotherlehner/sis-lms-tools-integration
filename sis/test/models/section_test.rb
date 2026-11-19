require "test_helper"

class SectionTest < ActiveSupport::TestCase
  test "belongs to a course" do
    course = Course.create!(code: "COURSE-2", title: "Course Two")
    section = Section.create!(course: course, code: "01", title: "Section One")

    assert_equal course, section.course
  end
  # test "the truth" do
  #   assert true
  # end
end
