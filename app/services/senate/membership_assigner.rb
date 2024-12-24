module Senate
  class MembershipAssigner
  def call
    mandate = SenateMandate.current
    return puts "No active senate mandate found" unless mandate

    CandidateNomination.senate.qualified.includes(:person, :party).find_each do |nomination|
      next if nomination.person.parliament_id.blank?
      
      group = ParliamentaryGroup.find_by(
        senate_mandate: mandate,
        party: nomination.party
      )
      
      if group
        ParliamentaryGroupMembership.create!(
          parliamentary_group: group,
          candidate_nomination: nomination,
          role: 'member' # Default role
        )
      else
        puts "No parliamentary group found for #{nomination.person.name} (#{nomination.party.abbreviation})"
      end
    end
  end
  end
  end