# simplms

A very simple learning management system for local development and education.

**Do not deploy this application to production.** The seeded credentials are intentionally simple and are not suitable for a real service.

## Requirements

- Ruby 3.2.3
- Bundler
- Rails 7.1.6 (Rails `~> 7.1.6`)
- SQLite

The app follows the shared Rails and dependency versions in `../sis`; its `Gemfile.lock` pins the resolved libraries.

## Set up and run

From this directory:

```sh
bundle install
bin/rails db:setup
bin/rails server
```

Open [http://localhost:3000](http://localhost:3000) and sign in with one of these local demo accounts:

| Role | Username | Password |
| --- | --- | --- |
| Admin | `admin` | `admin` |
| Instructor | `instructor` | `instructor` |
| Student | `student` | `student` |

Passwords are stored as Rails password digests. The starter accounts use their username as their password for this local demo.

## Using the application

- The home page shows the current user's roles and course sections.
- Students open an enrolled section to view course content and mark custom activities complete.
- Instructors open an assigned section to add, edit, or remove custom-content activities and use its gradebook.
- The gradebook shows each enrolled student's activity completion and score, plus midterm and final grades. Enter grades from 0 to 100 and save them together.
- Admins see every section, both student and instructor controls, and a link to RailsAdmin at `/admin`. RailsAdmin provides record management for all LMS entities.

When an administrator creates a user in RailsAdmin without setting a password, the username is used as the initial password. Password changes are not exposed in the Phase 1 UI.

## Database and tests

All SQLite database files are stored under `storage/` in this directory.

```sh
bin/rails db:setup     # Create and seed the database
bin/rails db:reset     # Recreate the database and reload the demo data
bin/rails db:migrate   # Apply pending migrations
bin/rails test         # Run the test suite
```

The seed data includes the three demo users, one course with one section, an instructor assignment, a student enrollment, blank midterm/final grades for that student, and one custom-content activity.

## SIS synchronization

The LMS consumes OneRoster 1.2 roster data from the SIS and provides gradebook results for the SIS to consume. See [`../docs/oneroster.md`](../docs/oneroster.md) for the API roles, mappings, and sync script configuration.

## Remaining boundaries

The app uses server-rendered Rails pages and SQLite. It does not implement tool/LTI activities or semesters.
