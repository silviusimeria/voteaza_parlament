require "json"
require "date"

module Senate
  class UpdateSenatorsData
    def call
      clear_senators_data
      update_senators_data
    end

    private

    def clear_senators_data
      Person.update_all(parliament_id: nil)
    end

    def normalize_special_chars(str)
      str.tr("ŞşŢţ", "ȘșȚț")
    end

    def generate_slug(name)
      normalize_special_chars(name)
        .downcase
        .gsub("ș", "s").gsub("ț", "t")
        .gsub("ă", "a").gsub("â", "a").gsub("î", "i")
        .gsub(/[^a-z0-9\s-]/, "")
        .gsub(/\s+/, "-")
        .gsub(/-+/, "-")
        .gsub(/^-|-$/, "")
    end

    def find_people_by_name(name, people)
      # Normalize the senator name
      senator_name = normalize_special_chars(name).upcase
      matches = []

      # Find exact matches
      exact_matches = people.select { |p| normalize_special_chars(p.name).upcase == senator_name }
      matches.concat(exact_matches.map { |p| { person: p, match_type: "exact" } }) if exact_matches.any?

      # If no exact matches, try partial matches
      if matches.empty?
        name_parts = senator_name.split(/[\s-]+/)
        partial_matches = people.select do |p|
          person_parts = normalize_special_chars(p.name).upcase.split(/[\s-]+/)
          (name_parts & person_parts).length >= 2 # Match if at least 2 parts match
        end
        matches.concat(partial_matches.map { |p| { person: p, match_type: "partial" } }) if partial_matches.any?
      end

      # If still no matches, try slug matches
      if matches.empty?
        senator_slug = generate_slug(name)
        slug_matches = people.select { |p| p.slug == senator_slug }
        matches.concat(slug_matches.map { |p| { person: p, match_type: "slug" } }) if slug_matches.any?
      end

      matches
    end

    def get_person_context(person)
      current_mandate = SenateMandate.find_by(active: true)
      nominations = if current_mandate
                      CandidateNomination.where(person_id: person.id, election_id: current_mandate.election_id)
      else
                      []
      end

      {
        nominations: nominations.map { |n| "#{n.id}: #{n.county.name} - #{n.party.name} (#{n.kind})" },
        party_memberships: PartyMembership.where(person_id: person.id)
                                          .map { |m| "#{m.party.name} (#{m.role})" }
      }
    end

    def update_senators_data
      # Load senators data
      senators_file = Rails.root.join("public", "data", "senate", "senators_list.json")
      senators_data = JSON.parse(File.read(senators_file))

      # Get all people
      people = Person.all.to_a

      # Track various categories
      unique_matches = []  # Single matches that we can update
      multiple_matches = [] # Cases where we found multiple people
      mismatches = []     # No matches found
      errors = []         # Updates that failed

      senators_data["senators"].each do |senator|
        matches = find_people_by_name(senator["name"], people)

        if matches.empty?
          mismatches << {
            name: senator["name"].upcase,
            normalized: normalize_special_chars(senator["name"].upcase),
            parliament_id: senator["parliament_id"]
          }
        elsif matches.length == 1
          # Single match - we can update
          person = matches.first[:person]
          begin
            dob = Date.strptime(senator["dob"], "%d.%m.%Y")
            person.update!(
              dob: dob,
              parliament_id: senator["parliament_id"]
            )

            unique_matches << {
              senator_name: senator["name"].upcase,
              matched_person: person.name,
              match_method: matches.first[:match_type],
              parliament_id: senator["parliament_id"]
            }
          rescue => e
            errors << {
              senator_name: senator["name"].upcase,
              error: e.message
            }
          end
        else
          # Multiple matches - need manual review
          context_info = matches.map do |match|
            person = match[:person]
            context = get_person_context(person)
            {
              person_id: person.id,
              name: person.name,
              match_type: match[:match_type],
              current_parliament_id: person.parliament_id,
              new_parliament_id: senator["parliament_id"],
              nominations: context[:nominations],
              party_memberships: context[:party_memberships]
            }
          end

          multiple_matches << {
            senator_name: senator["name"],
            parliament_id: senator["parliament_id"],
            matches: context_info
          }
        end
      end

      # Print results
      puts "\n=== SENATORS DATA UPDATE REPORT ==="
      puts "\nUnique Matches (Updated) - #{unique_matches.count}:"
      unique_matches.each do |match|
        method_indicator = case match[:match_method]
        when "exact" then "="
        when "partial" then "≈"
        when "slug" then "~"
        end
        puts "#{method_indicator} #{match[:senator_name]} => #{match[:matched_person]}"
        puts "  Parliament ID: #{match[:parliament_id]}"
      end

      if multiple_matches.any?
        puts "\n!!! MANUAL REVIEW NEEDED - #{multiple_matches.count} cases !!!"
        puts "The following senators matched multiple people and need manual review:"

        multiple_matches.each do |match|
          puts "\nSenator: #{match[:senator_name]}"
          puts "Parliament ID to assign: #{match[:parliament_id]}"
          puts "\nPotential matches:"

          match[:matches].each do |potential|
            puts "\n  Person ID: #{potential[:person_id]}"
            puts "  Name: #{potential[:name]}"
            puts "  Match type: #{potential[:match_type]}"
            puts "  Current Parliament ID: #{potential[:current_parliament_id]}"

            if potential[:nominations].any?
              puts "  Current Nominations:"
              potential[:nominations].each { |nom| puts "    - #{nom}" }
            end

            if potential[:party_memberships].any?
              puts "  Party Memberships:"
              potential[:party_memberships].each { |mem| puts "    - #{mem}" }
            end
          end
          puts "\n" + "-" * 50
        end
      end

      if mismatches.any?
        puts "\nUnmatched Senators - #{mismatches.count}:"
        mismatches.each do |mismatch|
          puts "✗ #{mismatch[:name]}"
          puts "  Normalized form: #{mismatch[:normalized]}"
          puts "  Parliament ID: #{mismatch[:parliament_id]}"
        end
      end

      if errors.any?
        puts "\nUpdate Errors - #{errors.count}:"
        errors.each do |error|
          puts "! #{error[:senator_name]}: #{error[:error]}"
        end
      end

      # Write detailed report to file
      report_file = Rails.root.join("log", "senators_update_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log")
      File.open(report_file, "w") do |f|
        f.puts "=== SENATORS DATA UPDATE REPORT ==="
        f.puts "Generated at: #{Time.now}"
        f.puts "\nSTATISTICS:"
        f.puts "- Total senators processed: #{senators_data['senators'].count}"
        f.puts "- Unique matches: #{unique_matches.count}"
        f.puts "- Multiple matches requiring review: #{multiple_matches.count}"
        f.puts "- Unmatched senators: #{mismatches.count}"
        f.puts "- Errors: #{errors.count}"

        # Write the same detailed information as console output
        # [... same formatting as above console output ...]
      end

      puts "\nDetailed report written to: #{report_file}"
    end
  end
end
