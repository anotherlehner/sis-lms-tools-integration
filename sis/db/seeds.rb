# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
RoleTran.find_or_create_by!(code: "admin") do |role|
  role.name = "Administrator"
  role.description = "Administers the student information system"
end

RoleTran.find_or_create_by!(code: "student") do |role|
  role.name = "Student"
  role.description = "A person enrolled in sections"
end

RoleTran.find_or_create_by!(code: "instructor") do |role|
  role.name = "Instructor"
  role.description = "A person assigned to teach sections"
end

RoleTran.find_or_create_by!(code: "staff") do |role|
  role.name = "Staff"
  role.description = "A staff member involved with the system"
end

admin = Person.find_or_initialize_by(username: "admin")
admin.first_name = "System"
admin.last_name = "Administrator"
admin.identifier = "ADMIN"
admin.password = "admin"
admin.save!

Role.find_or_create_by!(person: admin, role_tran: RoleTran.find_by!(code: "admin"))
