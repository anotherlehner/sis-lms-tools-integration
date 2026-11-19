# simplsis

A simple bare bones SIS system for demonstrating technologies and patterns.

This is an educational local-development application. It uses plain-text passwords and should not be deployed to production.

## Phase 1

- SQLite database stored below this folder
- Ruby on Rails application with Rails Admin CRUD
- One seeded administrator with username `admin` and plain-text password `admin`
- People, courses, sections, enrollments, instructors, grades, roles, and role translations
- Section-based student enrollments and instructor assignments
- Midterm and final grade fields on enrollments
- Activity grade records for student enrollments
- Minimal server-rendered HTML and no custom JavaScript
- Minitest model and integration coverage

## Setup

From this folder:

```sh
bundle install
ruby bin/create_db.rb
```

The seeded administrator is `admin` / `admin`.

## Running

```sh
bundle exec rails server
```

Open `http://localhost:3000/login`, or go directly to `http://localhost:3000/admin`.

## Database scripts

Run these from this folder:

```sh
ruby bin/create_db.rb
ruby bin/migrate_db.rb
ruby bin/recreate_db.rb
ruby bin/reset_db.rb
```

- `create_db.rb` creates, migrates, and seeds the development database.
- `migrate_db.rb` applies pending migrations.
- `recreate_db.rb` drops, recreates, migrates, and seeds the database.
- `reset_db.rb` resets the database through Rails and loads seeds.

## Tests

```sh
bundle exec rails test
```
