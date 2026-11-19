require "securerandom"

class AddGradeResultSourcedIds < ActiveRecord::Migration[7.1]
  def up
    add_column :grades, :one_roster_sourced_id, :string
    add_column :enrollments, :midterm_result_sourced_id, :string
    add_column :enrollments, :final_result_sourced_id, :string

    select_values("SELECT id FROM grades").each do |id|
      sourced_id = SecureRandom.uuid
      execute "UPDATE grades SET one_roster_sourced_id = '#{sourced_id}' WHERE id = #{id}"
    end
    select_values("SELECT id FROM enrollments").each do |id|
      midterm_id = SecureRandom.uuid
      final_id = SecureRandom.uuid
      execute "UPDATE enrollments SET midterm_result_sourced_id = '#{midterm_id}', final_result_sourced_id = '#{final_id}' WHERE id = #{id}"
    end

    add_index :grades, :one_roster_sourced_id, unique: true
    add_index :enrollments, :midterm_result_sourced_id, unique: true
    add_index :enrollments, :final_result_sourced_id, unique: true
  end

  def down
    remove_index :enrollments, :final_result_sourced_id
    remove_index :enrollments, :midterm_result_sourced_id
    remove_index :grades, :one_roster_sourced_id
    remove_column :enrollments, :final_result_sourced_id
    remove_column :enrollments, :midterm_result_sourced_id
    remove_column :grades, :one_roster_sourced_id
  end
end
