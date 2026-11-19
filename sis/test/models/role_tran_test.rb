require "test_helper"

class RoleTranTest < ActiveSupport::TestCase
  test "requires a unique role code" do
    RoleTran.create!(code: "student", name: "Student", description: "Student role")
    duplicate = RoleTran.new(code: "student", name: "Student", description: "Duplicate")

    assert_not duplicate.valid?
  end
  # test "the truth" do
  #   assert true
  # end
end
