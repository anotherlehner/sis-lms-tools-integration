class CreateSections < ActiveRecord::Migration[7.1]
  def change
    create_table :sections do |t|
      t.references :course, null: false, foreign_key: true
      t.string :code, null: false
      t.string :title, null: false

      t.timestamps
    end

    add_index :sections, [:course_id, :code], unique: true
  end
end
