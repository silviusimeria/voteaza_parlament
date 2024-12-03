class CandidateQualificationService
  def self.update_qualifications(election)
    ElectionPartyCountyResult.where(election: election).find_each do |result|
      qualified_candidates_count = {
        senate: result.senate_mandates || 0,
        deputy: result.deputy_mandates || 0
      }

      CandidateNomination.where(
        election: election,
        county_id: result.county_id,
        party_id: result.party_id
      ).update_all(qualified: false)

      [:senate, :deputy].each do |kind|
        next if qualified_candidates_count[kind].zero?

        CandidateNomination.where(
          election: election,
          county_id: result.county_id,
          party_id: result.party_id,
          kind: kind
        ).order(:position)
                           .limit(qualified_candidates_count[kind])
                           .update_all(qualified: true)
      end
    end
  end
end