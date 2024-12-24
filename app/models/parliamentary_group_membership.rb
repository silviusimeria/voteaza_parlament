class ParliamentaryGroupMembership < ApplicationRecord
  belongs_to :parliamentary_group
  belongs_to :candidate_nomination
  
  validates :parliamentary_group, presence: true
  validates :candidate_nomination, presence: true
  validates :candidate_nomination_id, uniqueness: { scope: :parliamentary_group_id }
  
  # Common roles that can be used
  ROLES = %w[
    leader
    vice_leader
    secretary
    member
  ].freeze
  
  validates :role, inclusion: { in: ROLES }, allow_nil: true
  
  delegate :senate_mandate, to: :parliamentary_group
  
  def self.for_mandate(mandate)
    joins(:parliamentary_group).where(parliamentary_groups: { senate_mandate: mandate })
  end
  
  def self.current
    for_mandate(SenateMandate.current)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["candidate_nomination_id", "created_at", "id", "id_value", "official_id", "parliamentary_group_id", "role", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["candidate_nomination", "parliamentary_group"]
  end
end