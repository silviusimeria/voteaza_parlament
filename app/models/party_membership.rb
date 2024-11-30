class PartyMembership < ApplicationRecord
  belongs_to :party
  belongs_to :person

  validates :role, presence: true

  def self.ransackable_associations(auth_object = nil)
    ["party", "person"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "end_date", "id", "party_id", "person_id", "role", "start_date", "updated_at"]
  end
end