class Instructor < ApplicationRecord
  include OneRosterSourced

  belongs_to :person
  belongs_to :section

  validates :person_id, uniqueness: { scope: :section_id }
end
