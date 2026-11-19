class Enrollment < ApplicationRecord
  include OneRosterSourced

  belongs_to :person
  belongs_to :section
  has_many :grades, dependent: :destroy

  validates :person_id, uniqueness: { scope: :section_id }
end
