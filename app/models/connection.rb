class Connection < ApplicationRecord
  belongs_to :person
  belongs_to :connected_person, class_name: "Person"

  validates :relationship_type, presence: true
  validates :person_id, uniqueness: {
    scope: [ :connected_person_id, :relationship_type ],
    message: "connection already exists"
  }
end
