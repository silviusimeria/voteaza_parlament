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


  def self.ransackable_attributes(auth_object = nil)
    [ "county_id", "created_at", "deputy_mandates", "election_id", "id", "id_value", "party_id", "percentage_cd", "percentage_senate", "senate_mandates", "updated_at", "votes_cd", "votes_senate" ]
  end
  def self.ransackable_associations(auth_object = nil)
    [ "county", "election", "election_party_county_result", "party" ]
  end
end
