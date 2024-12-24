class PermanentBureauMembership < ApplicationRecord
  belongs_to :senate_mandate
  belongs_to :candidate_nomination
  
  validates :senate_mandate, presence: true
  validates :candidate_nomination, presence: true
  validates :role, presence: true
  validates :candidate_nomination_id, uniqueness: { scope: :senate_mandate_id }
  
  # Common roles that can be used
  ROLES = %w[
    president
    vice_president
    secretary
    quaestor
  ].freeze
  
  validates :role, inclusion: { in: ROLES }
  
  def self.president
    find_by(role: 'president')
  end
end