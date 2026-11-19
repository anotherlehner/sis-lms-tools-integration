class CreateRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :roles do |t|
      t.references :person, null: false, foreign_key: true
      t.references :role_tran, null: false, foreign_key: true

      t.timestamps
    end

    add_index :roles, [:person_id, :role_tran_id], unique: true
  end
end
