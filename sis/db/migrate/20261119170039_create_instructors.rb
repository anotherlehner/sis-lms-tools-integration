class CreateInstructors < ActiveRecord::Migration[7.1]
  def change
    create_table :instructors do |t|
      t.references :person, null: false, foreign_key: true
      t.references :section, null: false, foreign_key: true

      t.timestamps
    end

    add_index :instructors, [:person_id, :section_id], unique: true
  end
end
