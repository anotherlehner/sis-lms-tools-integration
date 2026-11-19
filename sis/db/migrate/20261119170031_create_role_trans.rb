class CreateRoleTrans < ActiveRecord::Migration[7.1]
  def change
    create_table :role_trans do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.text :description, null: false

      t.timestamps
    end

    add_index :role_trans, :code, unique: true
  end
end
