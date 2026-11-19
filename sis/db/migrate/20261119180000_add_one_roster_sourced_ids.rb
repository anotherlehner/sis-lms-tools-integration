require "securerandom"

class AddOneRosterSourcedIds < ActiveRecord::Migration[7.1]
  TABLES = %i[people courses sections enrollments instructors].freeze

  def up
    TABLES.each do |table|
      add_column table, :one_roster_sourced_id, :string
    end

    TABLES.each do |table|
      select_values("SELECT id FROM #{table}").each do |id|
        sourced_id = SecureRandom.uuid
        execute "UPDATE #{table} SET one_roster_sourced_id = '#{sourced_id}' WHERE id = #{id}"
      end
      add_index table, :one_roster_sourced_id, unique: true
    end
    add_index :grades, %i[enrollment_id activity_identifier],
      unique: true,
      where: "activity_identifier IS NOT NULL",
      name: "index_grades_on_enrollment_and_activity_identifier"
  end

  def down
    remove_index :grades, name: "index_grades_on_enrollment_and_activity_identifier"
    TABLES.each do |table|
      remove_index table, :one_roster_sourced_id
      remove_column table, :one_roster_sourced_id
    end
  end
end
