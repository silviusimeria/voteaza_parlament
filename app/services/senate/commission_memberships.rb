# app/services/senate/import_commission_memberships.rb
module Senate
  class CommissionMemberships
    ROLE_MAPPING = {
      "Preşe" => "president",
      "Vicepreşe" => "vice_president",
      "Membru" => "member",
      "Secretar" => "secretary",
      "Chestor" => "quaestor"
    }

    def self.call
      new.call
    end

    def call
      ActiveRecord::Base.transaction do
        @senate_mandate = SenateMandate.find_by(active: true)
        unless @senate_mandate
          puts "No active senate mandate found!"
          return
        end

        # Debug: Let's check Parliament IDs in our DB
        puts "\nChecking Parliament IDs in database:"
        sample_people = Person.where.not(parliament_id: nil).limit(5)
        sample_people.each do |person|
          puts "DB Person: #{person.name} | ID: #{person.parliament_id} | Length: #{person.parliament_id&.length}"
        end

        import_commissions(@senate_mandate)
      end
    end

    private

    def find_person_by_parliament_id(parliament_id)
      # Try exact match first
      person = Person.where("UPPER(parliament_id) = UPPER(?)", parliament_id).first
      return person if person

      # If no match, try without dashes
      person = Person.where("UPPER(REPLACE(parliament_id, '-', '')) = UPPER(REPLACE(?, '-', ''))", parliament_id).first
      return person if person

      # Last try: Find by similar format (allowing for case differences and dashes)
      normalized_id = parliament_id.gsub(/[^A-F0-9]/i, '')
      Person.where("UPPER(REPLACE(parliament_id, '-', '')) = UPPER(?)", normalized_id).first
    end

    def import_commissions(senate_mandate)
      data = load_json_data
      stats = { created: 0, skipped: 0, errors: [] }
      multiple_matches = []
      failed_matches = []

      data["commissions"].each do |commission_data|
        commission = find_or_create_commission(senate_mandate, commission_data)
        puts "\nProcessing commission: #{commission.name}"

        commission_data["members"].each do |member_data|
          begin
            parliament_id = member_data["parlamentarId"]
            puts "\nProcessing member: #{member_data['name']} (#{parliament_id})"

            person = find_person_by_parliament_id(parliament_id)
            unless person
              stats[:skipped] += 1
              puts "  Could not find person with parliament_id: #{parliament_id}"
              failed_matches << {
                name: member_data["name"],
                parliament_id: parliament_id,
                commission: commission.name,
                role: ROLE_MAPPING[member_data["role"]]
              }
              next
            end

            puts "  Found person: #{person.name} (ID: #{person.id})"
            nomination = find_current_nomination(person)
            unless nomination
              stats[:skipped] += 1
              puts "  No current nomination found for #{person.name}"
              next
            end

            # Handle potential multiple nominations
            if person.candidate_nominations.where(election_id: @senate_mandate.election_id).count > 1
              multiple_matches << {
                name: member_data["name"],
                person_id: person.id,
                parliament_id: parliament_id,
                commission: commission.name,
                role: ROLE_MAPPING[member_data["role"]],
                nominations: person.candidate_nominations
                                   .where(election_id: @senate_mandate.election_id)
                                   .map { |n| "#{n.id}: #{n.county.name} - #{n.party.name}" }
              }
              stats[:skipped] += 1
              next
            end

            membership = SenateCommissionMembership.find_or_initialize_by(
              senate_commission: commission,
              candidate_nomination: nomination,
              role: ROLE_MAPPING[member_data["role"]],
              official_id: parliament_id
            )
            membership.save!
            puts "  Created membership for #{person.name}"
            stats[:created] += 1

          rescue => e
            stats[:errors] << {
              name: member_data["name"],
              error: e.message
            }
            puts "  ! Error processing #{member_data['name']} - #{ROLE_MAPPING[member_data["role"]]}: #{e.message}"
          end
        end
      end

      output_results(stats, multiple_matches, failed_matches)
    end

    def load_json_data
      file_path = Rails.root.join('public', 'data', 'senate', 'commission_members.json')
      JSON.parse(File.read(file_path))
    end

    def find_or_create_commission(senate_mandate, data)
      commission = SenateCommission.find_or_initialize_by(
        senate_mandate: senate_mandate,
        official_id: data["id"]
      )

      commission.update!(
        name: data["name"],
        short_name: data["short_name"],
        commission_type: data["type"]
      )

      commission
    end

    def find_current_nomination(person)
      CandidateNomination.find_by(
        person: person,
        election_id: @senate_mandate.election_id,
        kind: 'senate'
      )
    end

    def output_results(stats, multiple_matches, failed_matches)
      puts "\nCommission Memberships Import Complete!"
      puts "Created: #{stats[:created]}"
      puts "Skipped: #{stats[:skipped]}"

      if failed_matches.any?
        puts "\nFailed to find these parliament IDs:"
        failed_matches.each do |match|
          puts "\nName: #{match[:name]}"
          puts "Parliament ID: #{match[:parliament_id]}"
          puts "Commission: #{match[:commission]}"
          puts "Role: #{match[:role]}"
        end
      end

      if multiple_matches.any?
        puts "\nPeople with multiple nominations that need review:"
        multiple_matches.each do |match|
          puts "\nName: #{match[:name]}"
          puts "Person ID: #{match[:person_id]}"
          puts "Parliament ID: #{match[:parliament_id]}"
          puts "Commission: #{match[:commission]}"
          puts "Role: #{match[:role]}"
          puts "Nominations:"
          match[:nominations].each do |nom|
            puts "  - #{nom}"
          end
        end
      end

      if stats[:errors].any?
        puts "\nErrors encountered:"
        stats[:errors].each do |error|
          puts "- #{error[:name]}: #{error[:error]}"
        end
      end

      # Write a detailed report file
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      report_file = Rails.root.join("log/commission_import_#{timestamp}.log")

      File.open(report_file, 'w') do |f|
        f.puts "=== Commission Memberships Import Report ==="
        f.puts "Generated at: #{Time.current}"
        f.puts "\nSTATISTICS:"
        f.puts "Created: #{stats[:created]}"
        f.puts "Skipped: #{stats[:skipped]}"

        if failed_matches.any?
          f.puts "\nFAILED PARLIAMENT ID MATCHES:"
          failed_matches.each do |match|
            f.puts "\nName: #{match[:name]}"
            f.puts "Parliament ID: #{match[:parliament_id]}"
            f.puts "Commission: #{match[:commission]}"
            f.puts "Role: #{match[:role]}"
          end
        end

        if multiple_matches.any?
          f.puts "\nPEOPLE WITH MULTIPLE NOMINATIONS:"
          multiple_matches.each do |match|
            f.puts "\nName: #{match[:name]}"
            f.puts "Person ID: #{match[:person_id]}"
            f.puts "Parliament ID: #{match[:parliament_id]}"
            f.puts "Commission: #{match[:commission]}"
            f.puts "Role: #{match[:role]}"
            f.puts "Nominations:"
            match[:nominations].each do |nom|
              f.puts "  - #{nom}"
            end
          end
        end

        if stats[:errors].any?
          f.puts "\nERRORS:"
          stats[:errors].each do |error|
            f.puts "- #{error[:name]}: #{error[:error]}"
          end
        end
      end

      puts "\nDetailed report written to: #{report_file}"
    end
  end
end