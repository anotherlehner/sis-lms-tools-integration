class CreateLmsSchema < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :identifier, null: false
      t.string :username, null: false
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :users, :identifier, unique: true
    add_index :users, :username, unique: true

    create_table :roles do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :roles, :name, unique: true
    add_check_constraint :roles, "name IN ('student', 'admin', 'instructor')", name: "roles_name_valid"

    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.timestamps
    end
    add_index :user_roles, %i[user_id role_id], unique: true

    create_table :courses do |t|
      t.string :title, null: false
      t.text :description, null: false, default: ""
      t.text :objectives, null: false, default: ""
      t.timestamps
    end

    create_table :sections do |t|
      t.references :course, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end

    create_table :enrollments do |t|
      t.references :section, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :enrollments, %i[section_id user_id], unique: true

    create_table :teaching_assignments do |t|
      t.references :section, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :teaching_assignments, %i[section_id user_id], unique: true

    create_table :activities do |t|
      t.references :course, null: false, foreign_key: true
      t.string :title, null: false
      t.string :activity_type, null: false, default: "custom_content"
      t.text :content, null: false, default: ""
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_check_constraint :activities, "activity_type IN ('custom_content', 'tool')", name: "activities_type_valid"

    create_table :activity_completions do |t|
      t.references :activity, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :completed_at
      t.decimal :score, precision: 5, scale: 2
      t.timestamps
    end
    add_index :activity_completions, %i[activity_id user_id], unique: true
    add_check_constraint :activity_completions, "score IS NULL OR (score >= 0 AND score <= 100)", name: "activity_completion_score_valid"

    create_table :section_grades do |t|
      t.references :section, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :midterm_grade, precision: 5, scale: 2
      t.decimal :final_grade, precision: 5, scale: 2
      t.timestamps
    end
    add_index :section_grades, %i[section_id user_id], unique: true
    add_check_constraint :section_grades, "midterm_grade IS NULL OR (midterm_grade >= 0 AND midterm_grade <= 100)", name: "section_midterm_grade_valid"
    add_check_constraint :section_grades, "final_grade IS NULL OR (final_grade >= 0 AND final_grade <= 100)", name: "section_final_grade_valid"
  end
end
