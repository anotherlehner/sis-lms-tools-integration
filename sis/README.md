# simplsis

A simple bare bones SIS system for demonstrating technologies and patterns.

## Phase 1

- SQLite database on disk in this folder
- ruby on rails admin application with 1 users ("admin"), who logs in with a simple plain text password and has rails admin tools to add/edit/delete rows in all the database tables
- entities
 - courses
 - sections (should link to course)
 - enrollments (should link people to courses as students, store midterm and final grades when the person is a student)
 - instructors (should link people to courses as instructors)
 - grades (for all the activities students will do)
 - people (contains all people that are involved with the system, admin users, students, faculty, and staff)
 - roles (admin/student/instructor/staff roles that can be linked to people)
 - roles_tran (admin/student/instructor/staff roles and their descriptions)
- simple ruby scripts to reset, recreate, create, migrate the database
- unit tests
- as little javascript as possible, try to use none if possible

