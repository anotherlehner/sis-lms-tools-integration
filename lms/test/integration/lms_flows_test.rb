require "test_helper"

class LmsFlowsTest < ActionDispatch::IntegrationTest
  setup do
    @student_role = Role.create!(name: "student")
    @admin_role = Role.create!(name: "admin")
    @instructor_role = Role.create!(name: "instructor")
    @student = create_user("student", @student_role)
    @instructor = create_user("instructor", @instructor_role)
    @admin = create_user("admin", @admin_role)
    @course = Course.create!(title: "History", description: "Course overview", objectives: "Study history")
    @section = Section.create!(course: @course, name: "Section A")
    @other_section = Section.create!(course: @course, name: "Section B")
    Enrollment.create!(section: @section, user: @student)
    TeachingAssignment.create!(section: @section, user: @instructor)
    @activity = Activity.create!(
      course: @course,
      title: "Reading",
      activity_type: "custom_content",
      content: "Read this passage."
    )
  end

  test "requires a valid login and establishes the user session" do
    get root_path
    assert_redirected_to "/login"

    post lms_login_create_path, params: { username: "student" }
    assert_response :unprocessable_content

    post lms_login_create_path, params: { username: "student", password: "wrong" }
    assert_response :unprocessable_content

    post lms_login_create_path, params: { username: "student", password: "student" }
    assert_redirected_to root_path
    follow_redirect!
    assert_select "h1", "Welcome, #{ @student.first_name }"
    assert_select "a", text: "History"
  end

  test "students can access their section and complete course activities" do
    sign_in(@student)

    get course_section_path(@course, @section)
    assert_response :success
    assert_select "h1", "History"
    assert_select "button", text: "Mark complete"

    patch complete_course_section_activity_path(@course, @section, @activity)
    assert_redirected_to course_section_path(@course, @section)
    assert @activity.activity_completions.find_by!(user: @student).completed_at

    get course_section_path(@course, @other_section)
    assert_redirected_to root_path
  end

  test "instructors can manage custom activities and enter grades" do
    sign_in(@instructor)

    post course_section_activities_path(@course, @section), params: {
      activity: { title: "New reading", content: "New course content" }
    }
    assert_redirected_to course_section_path(@course, @section)
    assert_equal "New course content", @course.activities.find_by!(title: "New reading").content

    patch course_section_gradebook_path(@course, @section), params: {
      grades: { @student.id.to_s => { midterm_grade: "88", final_grade: "91" } },
      activity_grades: { @student.id.to_s => { @activity.id.to_s => { score: "95" } } }
    }
    assert_redirected_to course_section_gradebook_path(@course, @section)
    assert_equal 88, @section.section_grades.find_by!(user: @student).midterm_grade
    assert_equal 95, @activity.activity_completions.find_by!(user: @student).score
  end

  test "invalid grade changes roll back the entire gradebook update" do
    sign_in(@instructor)

    patch course_section_gradebook_path(@course, @section), params: {
      grades: { @student.id.to_s => { midterm_grade: "70", final_grade: "101" } },
      activity_grades: { @student.id.to_s => { @activity.id.to_s => { score: "90" } } }
    }

    assert_response :unprocessable_content
    assert_nil @section.section_grades.find_by!(user: @student).midterm_grade
    completion = @activity.activity_completions.find_by!(user: @student)
    assert_nil completion.score
    assert_nil completion.completed_at
  end

  test "admins see both student and instructor controls" do
    sign_in(@admin)

    get root_path
    assert_response :success
    assert_select "a", text: "Admin"
    assert_select "a", text: "History"

    get course_section_path(@course, @section)
    assert_select "button", text: "Mark complete"
    assert_select "summary", text: "Add custom content activity"

    get "/admin"
    assert_response :success
  end

  test "instructors cannot open RailsAdmin" do
    sign_in(@instructor)

    get "/admin"

    assert_redirected_to "/login"
  end

  test "users can have multiple roles" do
    @student.roles << @instructor_role

    assert @student.student?
    assert @student.instructor?
  end

  test "each enrolled student has a grade row for the section and activities" do
    assert @section.section_grades.exists?(user: @student)
    assert @activity.activity_completions.exists?(user: @student)
  end

  test "admins can create users through RailsAdmin" do
    sign_in(@admin)

    post "/admin/user/new", params: {
      user: {
        first_name: "New",
        last_name: "User",
        identifier: "identifier-new-user",
        username: "new-user"
      }
    }

    created_user = User.find_by!(username: "new-user")
    assert created_user.authenticate("new-user")
  end

  private

  def create_user(username, role)
    user = User.create!(
      first_name: username.capitalize,
      last_name: "Test",
      identifier: "identifier-#{username}",
      username: username,
      password: username
    )
    user.roles << role
    user
  end

  def sign_in(user)
    post lms_login_create_path, params: { username: user.username, password: user.username }
  end
end
