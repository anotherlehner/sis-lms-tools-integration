class CreateGrades < ActiveRecord::Migration[7.1]
  def change
    create_table :grades do |t|
      t.references :enrollment, null: false, foreign_key: true
      t.string :activity_identifier
      t.string :activity_name, null: false
      t.string :value, null: false
      t.text :comment

      t.timestamps
    end
  end
end
