module Senate
  class ParliamentIdChecker
    def call
      check_qualified_nominees_without_ids
      check_ids_without_qualified_nominees
    end

    private

    def check_qualified_nominees_without_ids
      nominees_without_ids = CandidateNomination.senate.qualified.includes(:person).select do |nomination|
        nomination.person.parliament_id.blank?
      end

      if nominees_without_ids.any?
        puts "\nQualified senate nominees without parliament IDs:"
        nominees_without_ids.each do |nomination|
          puts "- #{nomination.person.name} (#{nomination.party.abbreviation})"
        end
      end
    end

    def check_ids_without_qualified_nominees
      people_with_ids = Person.where.not(parliament_id: nil)
      ids_without_nominations = people_with_ids.select do |person|
        !person.candidate_nominations.senate.qualified.exists?
      end

      if ids_without_nominations.any?
        puts "\nPeople with parliament IDs but no qualified senate nomination:"
        ids_without_nominations.each do |person|
          puts "- #{person.name} (ID: #{person.parliament_id})"
        end
      end
    end
  end
end