class ParliamentController < ApplicationController
  def hemicycle
    @chamber = params[:chamber] || 'senate'
    @election = Election.find_by(name: 'Parliamentary Elections 2024')

    # Get all nominations with their associated data
    @seats = CandidateNomination.includes(:party, :county, :person)
                                .where(election: @election, kind: @chamber)
                                .where(qualified: true)
                                .map do |nomination|
      {
        id: nomination.id,
        name: nomination.name,
        party_name: nomination.party.name,
        party_color: nomination.party.color,
        county_name: nomination.county.name,
        slug: nomination.slug
      }
    end

    parties_under_threshold = @election.election_party_national_results
                                       .where(over_threshold_cd: false)
                                       .pluck(:party_id)

    @minority_candidates = CandidateNomination.includes(:party, :county)
                                             .where(election: @election,
                                                    party_id: parties_under_threshold,
                                                    kind: 'deputy',
                                                    qualified: true)
                                             .order('parties.name', :position)

    case @chamber
    when 'senate'
      @parties = Party.joins(:candidate_nominations, :election_party_national_results)
                      .where(candidate_nominations: { election: @election, kind: @chamber })
                      .where(election_party_national_results: { election: @election, over_threshold_senate: true})
                      .distinct
    when 'deputy'
      @parties = Party.joins(:candidate_nominations, :election_party_national_results)
                      .where(candidate_nominations: { election: @election, kind: @chamber })
                      .where(election_party_national_results: { election: @election, over_threshold_cd: true})
                      .distinct
    end
  end

  def senate
    @election = Election.find_by(name: 'Parliamentary Elections 2024')
    @mandate = SenateMandate.find_by(election: @election)

    # Get all mandate_started senators for hemicycle
    @seats = CandidateNomination.includes(:party, :county, :person, :parliamentary_group_memberships)
                                .where(election: @election, 
                                      kind: 'senate',
                                      mandate_started: true)
                                .map do |nomination|
                                  {
                                    id: nomination.id,
                                    name: nomination.person.name,
                                    party_name: nomination.parliamentary_group_memberships.first&.parliamentary_group&.name || nomination.party.name,
                                    party_color: nomination.party.color,
                                    county_name: nomination.county.name,
                                    slug: nomination.person.slug,
                                    group_id: nomination.parliamentary_group_memberships.first&.parliamentary_group_id
                                  }
    end

    # Load parliament groups with their members
    @parliament_groups = @mandate.parliamentary_groups
                                .includes(:party, 
                                        parliamentary_group_memberships: [
                                          candidate_nomination: [:person, :county]
                                        ])
                                .order(:name)

    # Load commissions
    @commissions = @mandate.senate_commissions
                          .includes(:senate_commission_memberships => {
                            candidate_nomination: [:person, :party]
                          })
                          .order(:name)
  end
end