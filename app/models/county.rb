class County < ApplicationRecord
  include Sluggable

  has_many :candidate_nominations
  has_many :parties, through: :candidate_nominations

  has_many :election_county_data
  has_many :elections, through: :election_county_data
  has_many :election_party_county_results
  has_many :candidate_nominations

  validates :name, :code, :geojson_id, presence: true

  def parties_with_candidates
    election = Election.current
    return [] unless election

    nominations_with_results = candidate_nominations.includes(:party)
                                                    .joins("LEFT JOIN election_party_results ON
          election_party_results.party_id = candidate_nominations.party_id
          AND election_party_results.county_id = candidate_nominations.county_id
          AND election_party_results.election_id = #{election.id}")
                                                    .joins("LEFT JOIN election_party_county_results ON
          election_party_county_results.party_id = candidate_nominations.party_id
          AND election_party_county_results.county_id = candidate_nominations.county_id
          AND election_party_county_results.election_id = #{election.id}")
                                                    .group_by(&:party)
                                                    .map do |party, candidates|
      votes_result = ElectionPartyResult.find_by(
        election: election,
        county_id: candidates.first.county_id,
        party: party
      )

      mandates_result = ElectionPartyCountyResult.find_by(
        election: election,
        county_id: candidates.first.county_id,
        party: party
      )

      PartyWithCandidates.new(
        party,
        candidates,
        votes_result,
        mandates_result
      )
    end.sort_by { |pwc| -pwc.senate_percentage }
  end

  def seats_for_election(election)
    data = election_county_data.find_by(election: election)
    {
      senate: data&.senate_seats || read_attribute(:senate_seats), # Fallback to old column
      deputy: data&.deputy_seats || read_attribute(:deputy_seats)  # Fallback to old column
    }
  end

  def party_results_for_election(election)
    election_party_county_results.where(election: election)
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[id name code geojson_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[candidate_nominations parties]
  end
end
