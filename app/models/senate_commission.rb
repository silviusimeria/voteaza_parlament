class SenateCommission < ApplicationRecord
  include Sluggable

  belongs_to :senate_mandate
  has_many :senate_commission_memberships
  has_many :candidate_nominations, through: :senate_commission_memberships

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :senate_mandate_id }
  validates :commission_type, presence: true

  COMMISSION_TYPES = %w[permanent investigation common].freeze
  validates :commission_type, inclusion: { in: COMMISSION_TYPES }

  scope :permanent, -> { where(commission_type: "permanent") }
  scope :investigation, -> { where(commission_type: "investigation") }
  scope :common, -> { where(commission_type: "common") }
  scope :for_mandate, ->(mandate) { where(senate_mandate: mandate) }
  scope :current, -> { for_mandate(SenateMandate.current) }

  def president
    senate_commission_memberships.find_by(role: "president")&.candidate_nomination
  end

  def vice_presidents
    senate_commission_memberships.where(role: "vice_president").map(&:candidate_nomination)
  end

  def secretary
    senate_commission_memberships.find_by(role: "secretary")&.candidate_nomination
  end

  def members
    senate_commission_memberships.where(role: "member").map(&:candidate_nomination)
  end
end
