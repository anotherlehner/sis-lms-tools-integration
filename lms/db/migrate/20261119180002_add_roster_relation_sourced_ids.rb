require "securerandom"

class AddRosterRelationSourcedIds < ActiveRecord::Migration[7.1]
  TABLES = %i[enrollments teaching_assignments].freeze

  def up
    TABLES.each do |table|
      add_column table, :one_roster_sourced_id, :string
      select_values("SELECT id FROM #{table}").each do |id|
        sourced_id = SecureRandom.uuid
        execute "UPDATE #{table} SET one_roster_sourced_id = '#{sourced_id}' WHERE id = #{id}"
      end
      add_index table, :one_roster_sourced_id, unique: true
    end
  end

  def down
    TABLES.each do |table|
      remove_index table, :one_roster_sourced_id
      remove_column table, :one_roster_sourced_id
    end
  end
end
