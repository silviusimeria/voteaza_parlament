class Election < ApplicationRecord
  has_many :election_county_data, dependent: :destroy
  has_many :counties, through: :election_county_data
  has_many :election_party_county_results, dependent: :destroy
  has_many :election_party_national_results
  has_many :election_party_results, dependent: :destroy
  has_many :candidate_nominations, dependent: :destroy
  has_many :parties, -> { distinct }, through: :candidate_nominations

  validates :name, presence: true
  validates :kind, presence: true
  validates :election_date, presence: true

  has_one :senate_mandate

  scope :parliament, -> { where(kind: 'parliament') }
  scope :active, -> { where(active: true) }

  def self.current
    active.first
  end

  def activate!
    Election.where.not(id: id).update_all(active: false)
    update!(active: true)
  end
end