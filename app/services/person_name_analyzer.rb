class PersonNameAnalyzer
  def self.analyze_same_names
    # Get all names that appear multiple times
    same_names = Person.group(:name)
                       .having("COUNT(*) > 1")
                       .pluck(:name)

    puts "Found #{same_names.length} names that appear multiple times"

    same_names.each do |name|
      people = Person.where(name: name)
      puts "\n=== Analyzing people named '#{name}' ==="
      puts "Found #{people.count} people with this name:"

      people.each do |person|
        nominations = CandidateNomination.where(person_id: person.id)
        puts "\nPerson ID: #{person.id}"
        puts "Created at: #{person.created_at}"
        puts "Parliament ID: #{person.parliament_id || 'None'}"
        puts "DOB: #{person.dob || 'Unknown'}"

        # Analyze nominations
        if nominations.any?
          puts "\nNominations:"
          nominations.group_by(&:election_id).each do |election_id, election_nominations|
            election = election_nominations.first.election
            puts "\nElection: #{election.name} (#{election.election_date})"

            election_nominations.each do |nom|
              puts "  - County: #{nom.county.name}"
              puts "    Party: #{nom.party.name}"
              puts "    Kind: #{nom.kind}"
              puts "    Position: #{nom.position}"
            end
          end
        else
          puts "No nominations found"
        end

        # Show party memberships for additional context
        memberships = PartyMembership.where(person_id: person.id)
        if memberships.any?
          puts "\nParty Memberships:"
          memberships.each do |mem|
            puts "  - #{mem.party.name} | Role: #{mem.role} | #{mem.start_date} - #{mem.end_date}"
          end
        end

        puts "\n------------------------"
      end

      # Analyze potential nomination conflicts
      analyze_nomination_conflicts(people)
    end
  end

  def self.analyze_nomination_conflicts(people)
    puts "\nAnalyzing potential nomination conflicts:"

    # Group all nominations by election
    election_nominations = people.flat_map do |person|
      CandidateNomination.where(person_id: person.id)
    end.group_by(&:election_id)

    election_nominations.each do |election_id, nominations|
      election = Election.find(election_id)

      # Check for same election + party + county combinations
      duplicates = nominations.group_by { |n| [ n.party_id, n.county_id ] }
                              .select { |_, noms| noms.size > 1 }

      if duplicates.any?
        puts "\nPossible conflicts in #{election.name}:"
        duplicates.each do |(party_id, county_id), noms|
          party = Party.find(party_id)
          county = County.find(county_id)
          puts "  Multiple nominations for #{party.name} in #{county.name}:"
          noms.each do |nom|
            person = Person.find(nom.person_id)
            puts "    - Person ID: #{person.id} | Position: #{nom.position} | Kind: #{nom.kind}"
          end
        end
      end

      # Check for unusual patterns (same person in multiple counties/parties)
      nominations.group_by(&:person_id).each do |person_id, person_noms|
        if person_noms.map(&:county_id).uniq.size > 1
          puts "\nPerson ID #{person_id} nominated in multiple counties in same election:"
          person_noms.each do |nom|
            puts "  - #{nom.county.name} | #{nom.party.name} | #{nom.kind} | Position: #{nom.position}"
          end
        end

        if person_noms.map(&:party_id).uniq.size > 1
          puts "\nPerson ID #{person_id} nominated by multiple parties in same election:"
          person_noms.each do |nom|
            puts "  - #{nom.party.name} | #{nom.county.name} | #{nom.kind} | Position: #{nom.position}"
          end
        end
      end
    end
  end
end
