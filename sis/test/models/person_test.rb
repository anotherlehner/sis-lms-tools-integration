require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "requires an admin login identity" do
    person = Person.new(first_name: "Test", last_name: "Person", username: "test", password: "test")

    assert person.valid?
  end

  test "recognizes an admin role" do
    role_tran = RoleTran.create!(code: "admin", name: "Administrator", description: "Administers the system")
    person = Person.create!(first_name: "Test", last_name: "Person", username: "test", password: "test")
    Role.create!(person: person, role_tran: role_tran)

    assert person.admin?
  end

  test "requires a unique username" do
    Person.create!(first_name: "One", last_name: "Person", username: "unique-test", password: "test")
    duplicate = Person.new(first_name: "Two", last_name: "Person", username: "unique-test", password: "test")

    assert_not duplicate.valid?
  end
  # test "the truth" do
  #   assert true
  # end
end
