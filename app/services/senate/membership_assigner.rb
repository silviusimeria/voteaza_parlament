module Senate
  class MembershipAssigner
  def call
    mandate = SenateMandate.current
    return puts "No active senate mandate found" unless mandate

    CandidateNomination.senate.where(mandate_started: true).includes(:person, :party).find_each do |nomination|
      next if nomination.person.parliament_id.blank?

      group = ParliamentaryGroup.find_by(
        senate_mandate: mandate,
        party: nomination.party
      )

      if group
        ParliamentaryGroupMembership.find_or_create_by!(
          parliamentary_group: group,
          candidate_nomination: nomination,
          role: "member" # Default role
        )
      else
        puts "No parliamentary group found for #{nomination.person.name} (#{nomination.party.abbreviation})"
      end
    end
  end
  end
end
