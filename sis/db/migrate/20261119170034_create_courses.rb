class CreateCourses < ActiveRecord::Migration[7.1]
  def change
    create_table :courses do |t|
      t.string :code, null: false
      t.string :title, null: false
      t.text :description

      t.timestamps
    end

    add_index :courses, :code, unique: true
  end
end
