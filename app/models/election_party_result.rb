class ElectionPartyResult < ApplicationRecord
  belongs_to :election
  belongs_to :county
  belongs_to :party

  has_one :election_party_county_result, ->(epr) {
    where(election_id: epr.election_id, county_id: epr.county_id, party_id: epr.party_id)
  }

  validates :votes_cd, :votes_senate,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :percentage_cd, :percentage_senate,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true
end