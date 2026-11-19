require "securerandom"

class AddOneRosterSourcedIds < ActiveRecord::Migration[7.1]
  UNIQUE_TABLES = %i[users courses sections activities activity_completions].freeze

  def up
    UNIQUE_TABLES.each do |table|
      add_column table, :one_roster_sourced_id, :string
    end
    add_column :section_grades, :midterm_sourced_id, :string
    add_column :section_grades, :final_sourced_id, :string

    UNIQUE_TABLES.each do |table|
      select_values("SELECT id FROM #{table}").each do |id|
        sourced_id = SecureRandom.uuid
        execute "UPDATE #{table} SET one_roster_sourced_id = '#{sourced_id}' WHERE id = #{id}"
      end
      add_index table, :one_roster_sourced_id, unique: true
    end

    select_values("SELECT id FROM section_grades").each do |id|
      midterm_id = SecureRandom.uuid
      final_id = SecureRandom.uuid
      execute "UPDATE section_grades SET midterm_sourced_id = '#{midterm_id}', final_sourced_id = '#{final_id}' WHERE id = #{id}"
    end
    add_index :section_grades, :midterm_sourced_id, unique: true
    add_index :section_grades, :final_sourced_id, unique: true
  end

  def down
    remove_index :section_grades, :final_sourced_id
    remove_index :section_grades, :midterm_sourced_id
    remove_column :section_grades, :final_sourced_id
    remove_column :section_grades, :midterm_sourced_id

    UNIQUE_TABLES.each do |table|
      remove_index table, :one_roster_sourced_id
      remove_column table, :one_roster_sourced_id
    end
  end
end
