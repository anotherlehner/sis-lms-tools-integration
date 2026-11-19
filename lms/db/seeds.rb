roles = Role::NAMES.index_with { |name| Role.find_or_create_by!(name: name) }

admin = User.find_or_initialize_by(username: "admin")
admin.assign_attributes(
  first_name: "Ada",
  last_name: "Administrator",
  identifier: "user-admin",
  password: "admin"
)
admin.save!
admin.roles = [roles.fetch("admin")]
admin.save!

instructor = User.find_or_initialize_by(username: "instructor")
instructor.assign_attributes(
  first_name: "Iris",
  last_name: "Instructor",
  identifier: "user-instructor",
  password: "instructor"
)
instructor.save!
instructor.roles = [roles.fetch("instructor")]
instructor.save!

student = User.find_or_initialize_by(username: "student")
student.assign_attributes(
  first_name: "Sam",
  last_name: "Student",
  identifier: "user-student",
  password: "student"
)
student.save!
student.roles = [roles.fetch("student")]
student.save!

course = Course.find_or_create_by!(title: "Introduction to Learning") do |record|
  record.description = "A sample course used to explore the simple LMS."
  record.objectives = "Explore course content and complete a custom activity."
end
section = Section.find_or_create_by!(course: course, name: "Section 1")
Enrollment.find_or_create_by!(section: section, user: student)
TeachingAssignment.find_or_create_by!(section: section, user: instructor)
SectionGrade.find_or_create_by!(section: section, user: student)

Activity.find_or_create_by!(course: course, title: "Welcome") do |record|
  record.activity_type = "custom_content"
  record.content = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer nec odio. Praesent libero. Sed cursus ante dapibus diam."
  record.position = 1
end
