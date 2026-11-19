class CreatePeople < ActiveRecord::Migration[7.1]
  def change
    create_table :people do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :username, null: false
      t.string :identifier
      t.string :password, null: false

      t.timestamps
    end

    add_index :people, :username, unique: true
    add_index :people, :identifier, unique: true
  end
end
