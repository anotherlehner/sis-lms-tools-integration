# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_11_20_150001) do
  create_table "activities", force: :cascade do |t|
    t.integer "course_id", null: false
    t.string "title", null: false
    t.string "activity_type", default: "custom_content", null: false
    t.text "content", default: "", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "one_roster_sourced_id"
    t.index ["course_id"], name: "index_activities_on_course_id"
    t.index ["one_roster_sourced_id"], name: "index_activities_on_one_roster_sourced_id", unique: true
    t.check_constraint "activity_type IN ('custom_content', 'tool')", name: "activities_type_valid"
  end

  create_table "activity_completions", force: :cascade do |t|
    t.integer "activity_id", null: false
    t.integer "user_id", null: false
    t.datetime "completed_at"
    t.decimal "score", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "one_roster_sourced_id"
    t.integer "attempt_count"
    t.index ["activity_id", "user_id"], name: "index_activity_completions_on_activity_id_and_user_id", unique: true
    t.index ["activity_id"], name: "index_activity_completions_on_activity_id"
    t.index ["one_roster_sourced_id"], name: "index_activity_completions_on_one_roster_sourced_id", unique: true
    t.index ["user_id"], name: "index_activity_completions_on_user_id"
    t.check_constraint "attempt_count IS NULL OR attempt_count > 0", name: "activity_completion_attempt_count_valid"
    t.check_constraint "score IS NULL OR (score >= 0 AND score <= 100)", name: "activity_completion_score_valid"
  end

  create_table "courses", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", default: "", null: false
    t.text "objectives", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "one_roster_sourced_id"
    t.string "course_code"
    t.index ["one_roster_sourced_id"], name: "index_courses_on_one_roster_sourced_id", unique: true
  end

  create_table "enrollments", force: :cascade do |t|
    t.integer "section_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "one_roster_sourced_id"
    t.index ["one_roster_sourced_id"], name: "index_enrollments_on_one_roster_sourced_id", unique: true
    t.index ["section_id", "user_id"], name: "index_enrollments_on_section_id_and_user_id", unique: true
    t.index ["section_id"], name: "index_enrollments_on_section_id"
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "lti_access_tokens", force: :cascade do |t|
    t.string "token_digest", null: false
    t.string "assertion_jti", null: false
    t.string "client_id", null: false
    t.string "scope", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assertion_jti"], name: "index_lti_access_tokens_on_assertion_jti", unique: true
    t.index ["token_digest"], name: "index_lti_access_tokens_on_token_digest", unique: true
  end

  create_table "lti_launches", force: :cascade do |t|
    t.integer "activity_id", null: false
    t.integer "section_id", null: false
    t.integer "user_id", null: false
    t.string "login_hint_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_lti_launches_on_activity_id"
    t.index ["login_hint_digest"], name: "index_lti_launches_on_login_hint_digest", unique: true
    t.index ["section_id"], name: "index_lti_launches_on_section_id"
    t.index ["user_id"], name: "index_lti_launches_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
    t.check_constraint "name IN ('student', 'admin', 'instructor')", name: "roles_name_valid"
  end

  create_table "section_grades", force: :cascade do |t|
    t.integer "section_id", null: false
    t.integer "user_id", null: false
    t.decimal "midterm_grade", precision: 5, scale: 2
    t.decimal "final_grade", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "midterm_sourced_id"
    t.string "final_sourced_id"
    t.index ["final_sourced_id"], name: "index_section_grades_on_final_sourced_id", unique: true
    t.index ["midterm_sourced_id"], name: "index_section_grades_on_midterm_sourced_id", unique: true
    t.index ["section_id", "user_id"], name: "index_section_grades_on_section_id_and_user_id", unique: true
    t.index ["section_id"], name: "index_section_grades_on_section_id"
    t.index ["user_id"], name: "index_section_grades_on_user_id"
    t.check_constraint "final_grade IS NULL OR (final_grade >= 0 AND final_grade <= 100)", name: "section_final_grade_valid"
    t.check_constraint "midterm_grade IS NULL OR (midterm_grade >= 0 AND midterm_grade <= 100)", name: "section_midterm_grade_valid"
  end

  create_table "sections", force: :cascade do |t|
    t.integer "course_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "one_roster_sourced_id"
    t.string "class_code"
    t.index ["course_id"], name: "index_sections_on_course_id"
    t.index ["one_roster_sourced_id"], name: "index_sections_on_one_roster_sourced_id", unique: true
  end

  create_table "teaching_assignments", force: :cascade do |t|
    t.integer "section_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "one_roster_sourced_id"
    t.index ["one_roster_sourced_id"], name: "index_teaching_assignments_on_one_roster_sourced_id", unique: true
    t.index ["section_id", "user_id"], name: "index_teaching_assignments_on_section_id_and_user_id", unique: true
    t.index ["section_id"], name: "index_teaching_assignments_on_section_id"
    t.index ["user_id"], name: "index_teaching_assignments_on_user_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "identifier", null: false
    t.string "username", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "one_roster_sourced_id"
    t.index ["identifier"], name: "index_users_on_identifier", unique: true
    t.index ["one_roster_sourced_id"], name: "index_users_on_one_roster_sourced_id", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "activities", "courses"
  add_foreign_key "activity_completions", "activities"
  add_foreign_key "activity_completions", "users"
  add_foreign_key "enrollments", "sections"
  add_foreign_key "enrollments", "users"
  add_foreign_key "lti_launches", "activities"
  add_foreign_key "lti_launches", "sections"
  add_foreign_key "lti_launches", "users"
  add_foreign_key "section_grades", "sections"
  add_foreign_key "section_grades", "users"
  add_foreign_key "sections", "courses"
  add_foreign_key "teaching_assignments", "sections"
  add_foreign_key "teaching_assignments", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
