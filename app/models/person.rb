class Person < ApplicationRecord
  has_many :party_memberships
  has_many :parties, through: :party_memberships
  has_many :candidate_nominations

  validates :name, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["id", "name", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["candidate_nominations", "parties", "party_memberships"]
  end
end