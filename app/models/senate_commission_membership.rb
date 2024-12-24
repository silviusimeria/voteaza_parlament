class SenateCommissionMembership < ApplicationRecord
  belongs_to :senate_commission
  belongs_to :candidate_nomination
  
  validates :senate_commission, presence: true
  validates :candidate_nomination, presence: true
  validates :candidate_nomination_id, uniqueness: { scope: :senate_commission_id }
  
  ROLES = %w[
    president
    vice_president
    secretary
    member
    quaestor
  ].freeze
  
  validates :role, inclusion: { in: ROLES }
  
  delegate :senate_mandate, to: :senate_commission
  
  def self.for_mandate(mandate)
    joins(:senate_commission).where(senate_commissions: { senate_mandate: mandate })
  end
  
  def self.current
    for_mandate(SenateMandate.current)
  end
end