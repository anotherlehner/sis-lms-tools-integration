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

ActiveRecord::Schema[7.1].define(version: 2026_11_19_180001) do
  create_table "courses", force: :cascade do |t|
    t.string "code", null: false
    t.string "title", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "one_roster_sourced_id"
    t.index ["code"], name: "index_courses_on_code", unique: true
    t.index ["one_roster_sourced_id"], name: "index_courses_on_one_roster_sourced_id", unique: true
  end

  create_table "enrollments", force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "section_id", null: false
    t.string "midterm_grade"
    t.string "final_grade"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "one_roster_sourced_id"
    t.string "midterm_result_sourced_id"
    t.string "final_result_sourced_id"
    t.index ["final_result_sourced_id"], name: "index_enrollments_on_final_result_sourced_id", unique: true
    t.index ["midterm_result_sourced_id"], name: "index_enrollments_on_midterm_result_sourced_id", unique: true
    t.index ["one_roster_sourced_id"], name: "index_enrollments_on_one_roster_sourced_id", unique: true
    t.index ["person_id", "section_id"], name: "index_enrollments_on_person_id_and_section_id", unique: true
    t.index ["person_id"], name: "index_enrollments_on_person_id"
    t.index ["section_id"], name: "index_enrollments_on_section_id"
  end

  create_table "grades", force: :cascade do |t|
    t.integer "enrollment_id", null: false
    t.string "activity_identifier"
    t.string "activity_name", null: false
    t.string "value", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "one_roster_sourced_id"
    t.index ["enrollment_id", "activity_identifier"], name: "index_grades_on_enrollment_and_activity_identifier", unique: true, where: "activity_identifier IS NOT NULL"
    t.index ["enrollment_id"], name: "index_grades_on_enrollment_id"
    t.index ["one_roster_sourced_id"], name: "index_grades_on_one_roster_sourced_id", unique: true
  end

  create_table "instructors", force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "section_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "one_roster_sourced_id"
    t.index ["one_roster_sourced_id"], name: "index_instructors_on_one_roster_sourced_id", unique: true
    t.index ["person_id", "section_id"], name: "index_instructors_on_person_id_and_section_id", unique: true
    t.index ["person_id"], name: "index_instructors_on_person_id"
    t.index ["section_id"], name: "index_instructors_on_section_id"
  end

  create_table "people", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "username", null: false
    t.string "identifier"
    t.string "password", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "one_roster_sourced_id"
    t.index ["identifier"], name: "index_people_on_identifier", unique: true
    t.index ["one_roster_sourced_id"], name: "index_people_on_one_roster_sourced_id", unique: true
    t.index ["username"], name: "index_people_on_username", unique: true
  end

  create_table "role_trans", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_role_trans_on_code", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "role_tran_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id", "role_tran_id"], name: "index_roles_on_person_id_and_role_tran_id", unique: true
    t.index ["person_id"], name: "index_roles_on_person_id"
    t.index ["role_tran_id"], name: "index_roles_on_role_tran_id"
  end

  create_table "sections", force: :cascade do |t|
    t.integer "course_id", null: false
    t.string "code", null: false
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "one_roster_sourced_id"
    t.index ["course_id", "code"], name: "index_sections_on_course_id_and_code", unique: true
    t.index ["course_id"], name: "index_sections_on_course_id"
    t.index ["one_roster_sourced_id"], name: "index_sections_on_one_roster_sourced_id", unique: true
  end

  add_foreign_key "enrollments", "people"
  add_foreign_key "enrollments", "sections"
  add_foreign_key "grades", "enrollments"
  add_foreign_key "instructors", "people"
  add_foreign_key "instructors", "sections"
  add_foreign_key "roles", "people"
  add_foreign_key "roles", "role_trans"
  add_foreign_key "sections", "courses"
end
