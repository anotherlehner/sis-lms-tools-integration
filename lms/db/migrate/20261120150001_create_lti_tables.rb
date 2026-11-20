class CreateLtiTables < ActiveRecord::Migration[7.1]
  def change
    create_table :lti_launches do |t|
      t.references :activity, null: false, foreign_key: true
      t.references :section, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :login_hint_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.timestamps
    end
    add_index :lti_launches, :login_hint_digest, unique: true

    create_table :lti_access_tokens do |t|
      t.string :token_digest, null: false
      t.string :assertion_jti, null: false
      t.string :client_id, null: false
      t.string :scope, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :lti_access_tokens, :token_digest, unique: true
    add_index :lti_access_tokens, :assertion_jti, unique: true
  end
end
