require "test_helper"

class SessionTest < ActionDispatch::IntegrationTest
  setup do
    admin_role = RoleTran.find_or_create_by!(code: "admin") do |role|
      role.name = "Administrator"
      role.description = "Administers the system"
    end
    @admin = Person.find_or_create_by!(username: "admin") do |person|
      person.first_name = "System"
      person.last_name = "Administrator"
      person.password = "admin"
    end
    Role.find_or_create_by!(person: @admin, role_tran: admin_role)
  end

  test "login page is public" do
    get sis_login_path

    assert_response :success
  end

  test "valid admin login opens Rails Admin" do
    post sis_login_post_path, params: { username: "admin", password: "admin" }

    assert_redirected_to rails_admin_path
  end

  test "invalid login does not create a session" do
    post sis_login_post_path, params: { username: "admin", password: "wrong" }

    assert_response :unprocessable_content
  end

  test "Rails Admin rejects an unauthenticated visitor" do
    get rails_admin_path

    assert_redirected_to "/login"
  end

  test "logout removes the session" do
    post sis_login_post_path, params: { username: "admin", password: "admin" }
    delete logout_path

    assert_redirected_to sis_login_path
  end
end
