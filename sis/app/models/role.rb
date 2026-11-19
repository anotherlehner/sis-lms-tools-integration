class Role < ApplicationRecord
  belongs_to :person
  belongs_to :role_tran

  validates :role_tran_id, uniqueness: { scope: :person_id }
end
