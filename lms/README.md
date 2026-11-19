# simplms

A very simple learning management system.

NOTE: THIS IS AN EDUCATIONAL LOCAL DEV PROJECT -- DO NOT DEPLOY IN PRODUCTION

## Phase 1

### Features

- SQLite database on disk in this folder (`lms`)
- users with first and last names, a unique identifier, and usernames and passwords
- user roles: student, admin, instructor
- users can have one or more roles (or even all three)
- entities: courses, sections, grades, activities
 - a course can have many sections, a course is the central definition of a class and what it's goals and objectives are
 - a section can have many student registrations (students enrolled in the section of the course)
 - courses and sections are connected by course id combined with section id (foreign key)
 - courses have a homepage where the content for the course lives (all sections of the course see this)
 - 
- there are no semesters, we need to keep this simple so that we focus on other priorities
- dynamic homepage that shows:
 - what roles the user has
 - what course sections the user is teaching
 - what course sections the user is a student in (taking)
 - admin controls
 - when clicked the link to a course being taken as a student should show the course homepage (and which section the student is in), along with student-available options
 - when clicked the link to a course being taught as an instructor should show the course homepage (and which sections the instructor is teaching), along with instructor-available options
- the web style should be very basic and clean, use simple stock modern rails development style and default styling
- course homepage
 - students and instructors see all the content
 - courses are made up of a list of activities
 - instructors can add/remove/edit activities
 - students can see and complete activities
- activities
 - there are two types of activity: custom content and tool
 - custom content activities are just text the instructor can enter and the student can see but not edit
 - tool content are activities that interact with external tool systems using the LTI integration standard (do not implement anything with LTI until phase 2)
- admins should be able to see admin controls on the homepage
 - admin controls include links to the rails admin pages for all the entity types in the system
 - admins can add/edit/delete all records in any table in the system
 - admins can follow all links and see instructor AND student controls (everything)
- initial data
 - there should be three users: admin, instructor, and student
 - passwords for these three users should all be blank to start
 - there should be one course with one section
 - the one course should have one custom activity with some lorem ipsum text
 - no tool activities should be defined yet (will be in phase 2)
- rosters
 - each course section should have a roster associated with it (the students registered for this section)
 - rosters will be synched with the external sis system using the OpenRoster 1edtech standard (during phase 2)
- grades
 - each course section should have grades for all the students for the course (mid term and final grades)
 - each course activity should be tracked with a grade for each student
 - grades for all students (activities and midterm and final grades) should be viewable by the instructor/admin for the section, this is called the "grade book" in the UI
 - the grades will eventually be synched to the external sis system using the the OneRoster standard (phase 2)
- courses and enrollments will be synched to the sis system using OneRoster standard

### System

- develop using ruby on rails
- batch imports/exports should be simple ruby scripts
- database should be SQLite with scripts to quickly create, recreate, reset the database
- don't use any javascript unless absolutely necessary
- users should authenticate with simple text passwords for this test
- there should be unit tests for all features (using modern rails development style)
- do not add comments
- keep the code as clean and simple as possible
- keep the code readable by a non-ruby practitioner (err on the side of readability over conciseness)

## Phase 2

TODO.
