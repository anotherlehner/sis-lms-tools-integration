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

For an existing database, run `bin/rails db:migrate` after pulling schema changes, then restart the Rails server so it reloads the updated model columns. The repository-level `./dev start lms` command handles pending LMS migrations and schema-triggered restarts automatically.

Open [http://localhost:3000](http://localhost:3000) and sign in with one of these local demo accounts:

| Role | Username | Password |
| --- | --- | --- |
| Admin | `admin` | `admin` |
| Instructor | `instructor` | `instructor` |
| Student | `student` | `student` |

Passwords are stored as Rails password digests. The starter accounts use their username as their password for this local demo.

## Using the application

- The home page shows the current user's roles and course sections.
- Students open an enrolled section to view course content, mark custom activities complete, and launch the Acme Guess the Number tool.
- Instructors open an assigned section to add, edit, or remove custom-content activities, add the Guess the Number tool, and use its gradebook.
- The gradebook shows each enrolled student's activity completion and score, including Guess the Number's attempt count, plus midterm and final grades. Enter grades from 0 to 100 and save them together.
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

The seed data includes the three demo users, one course with one section, an instructor assignment, a student enrollment, blank midterm/final grades for that student, and one custom-content activity. The LMS acts as the local LTI 1.3 platform for the Acme tool. Use `./dev start all` from the repository root to start the LMS, SIS, and Acme app together; see [`../tools/README.md`](../tools/README.md) for tool setup and launch details.

## SIS synchronization

The LMS consumes OneRoster 1.2 roster data from the SIS and provides gradebook results for the SIS to consume. See [`../docs/oneroster.md`](../docs/oneroster.md) for the API roles, mappings, and sync script configuration.

## LTI boundaries

The LTI integration uses a static local tool registration, LTI 1.3 Core launches, and AGS score reporting. It does not implement dynamic registration, Deep Linking, Names and Role Provisioning Services, or production key management.
