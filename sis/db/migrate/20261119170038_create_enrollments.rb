class CreateEnrollments < ActiveRecord::Migration[7.1]
  def change
    create_table :enrollments do |t|
      t.references :person, null: false, foreign_key: true
      t.references :section, null: false, foreign_key: true
      t.string :midterm_grade
      t.string :final_grade

      t.timestamps
    end

    add_index :enrollments, [:person_id, :section_id], unique: true
  end
end
