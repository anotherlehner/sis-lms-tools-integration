require "test_helper"

class CourseTest < ActiveSupport::TestCase
  test "requires a unique course code" do
    Course.create!(code: "COURSE-1", title: "Course One")
    duplicate = Course.new(code: "COURSE-1", title: "Duplicate")

    assert_not duplicate.valid?
  end
  # test "the truth" do
  #   assert true
  # end
end
