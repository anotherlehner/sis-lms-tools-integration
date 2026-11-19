require "test_helper"

class RoleTest < ActiveSupport::TestCase
  test "does not assign the same role twice" do
    role_tran = RoleTran.create!(code: "staff", name: "Staff", description: "Staff role")
    person = Person.create!(first_name: "Test", last_name: "Person", username: "staff-test", password: "test")
    Role.create!(person: person, role_tran: role_tran)
    duplicate = Role.new(person: person, role_tran: role_tran)

    assert_not duplicate.valid?
  end
  # test "the truth" do
  #   assert true
  # end
end
