class VoteResultsProcessor
  THRESHOLD = 5.0
  COUNTY_MAPPINGS_PATH = Rails.root.join("public", "county_mappings.json")

    def initialize(election, results_json)
      @election = election
      @results = JSON.parse(results_json)
      @county_mappings = load_county_mappings
      @party_votes_cd = Hash.new(0)
      @party_votes_senate = Hash.new(0)
      @total_votes_cd = 0
      @total_votes_senate = 0
      @mandates_by_county = {}
    end

  def process
    puts "Starting vote results processing for election #{@election.id}"
    data = @results["scopes"]
    process_county_results(data["CNTY"])
    calculate_thresholds
    # allocate_mandates
    process_national_results(data["CNTRY"])
    log_processing_results
  end


  private

    def load_county_mappings
      JSON.parse(File.read(COUNTY_MAPPINGS_PATH))
    end

    def find_county(aep_id)
      mapping = @county_mappings[aep_id]
      return nil unless mapping

      if mapping["type"] == "bucharest_sector"
        County.find_by(code: "B")
      elsif mapping["type"] == "diaspora"
        County.find_by(code: "D")
      else
        County.find_by(code: mapping["county_code"])
      end
    end

    def aggregate_bucharest_votes(cd_data, senate_data)
      sector_ids = @county_mappings.select { |_, m| m["type"] == "bucharest_sector" }.keys

      {
        cd: aggregate_chamber_votes(cd_data, sector_ids),
        senate: aggregate_chamber_votes(senate_data, sector_ids)
      }
    end

    def aggregate_chamber_votes(chamber_data, sector_ids)
      votes = Hash.new(0)

      sector_ids.each do |sector_id|
        next unless chamber_data[sector_id]&.dig("candidates")

        chamber_data[sector_id]["candidates"].each do |candidate|
          next unless candidate["id"]&.start_with?("P")
          party_name = candidate["candidate"]
          votes[party_name] += candidate["votes"].to_i
        end
      end

      votes
    end

    def process_county_results(data)
      cd_data = data["CD"]
      senate_data = data["S"]

      # Handle regular counties
      cd_data.each do |aep_id, cd_county_data|
        county = find_county(aep_id)
        puts county.name
        next unless county
        next if county.code == "B" # Skip individual Bucharest sectors

        senate_county_data = senate_data[aep_id]
        process_county(county.code, cd_county_data, senate_county_data)
      end

      # Handle Bucharest specially
      bucharest = County.find_by(code: "B")
      if bucharest
        votes = aggregate_bucharest_votes(cd_data, senate_data)
        process_aggregated_county(bucharest, votes)
      end
    end

    def process_aggregated_county(county, votes)
      votes[:cd].each do |party_name, cd_votes|
        party = Party.find_by(name: party_name)
        unless party
          puts "PARTY NOT FOUND " + party_name
          next
        end

        senate_votes = votes[:senate][party_name]
        save_county_result(county, party, cd_votes, senate_votes)

        @party_votes_cd[party_name] += cd_votes
        @party_votes_senate[party_name] += senate_votes
        @total_votes_cd += cd_votes
        @total_votes_senate += senate_votes
      end
    end

  def process_chamber_results(cd_data, senate_data)
    cd_data.each do |county_code, cd_county_data|
      senate_county_data = senate_data[county_code]
      next unless cd_county_data["candidates"] && senate_county_data["candidates"]

      process_county(county_code, cd_county_data, senate_county_data)
    end
  end

  def process_county(county_code, cd_data, senate_data)
    county = County.find_by(code: county_code)
    return unless county

    puts "Processing #{county.name} (#{county_code})"

    party_votes_cd = Hash.new(0)
    party_votes_senate = Hash.new(0)
    total_votes_cd = 0
    total_votes_senate = 0
    cd_data["candidates"].each do |candidate|
      # puts candidate
      if candidate["id"]&.start_with?("P")
        party_name = candidate["candidate"]
        party = Party.find_by(name: party_name)
        unless party
          puts "PARTY NOT FOUND " + party_name
          next
        end

        senate_votes = find_party_votes(senate_data["candidates"], party_name)
        cd_votes = candidate["votes"].to_i

        save_county_result(county, party, cd_votes, senate_votes)

        party_votes_cd[party_name] += cd_votes
        party_votes_senate[party_name] += senate_votes
        total_votes_cd += cd_votes
        total_votes_senate += senate_votes

        puts "#{county.name} - #{party.abbreviation}: CD=#{cd_votes}, Senate=#{senate_votes}"
      else
        candidate_name = candidate["candidate"]
        cd_votes = candidate["votes"].to_i
        senate_votes = find_party_votes(senate_data["candidates"], candidate_name)
        total_votes_cd += cd_votes
        total_votes_senate += senate_votes
        puts "#{candidate["candidate"]}: CD=#{cd_votes}, Senate=#{senate_votes}"
      end
    end

    ElectionPartyResult.where(county: county).all.each do |epr|
      percentage_cd =  calculate_percentage(epr.votes_cd, total_votes_cd)
      percentage_senate = calculate_percentage(epr.votes_senate, total_votes_senate)

      if percentage_cd > 100 || percentage_senate > 100
        puts "Weird #{epr.votes_senate}  #{epr.votes_cd}  #{total_votes_senate}  #{total_votes_cd}"
        puts "#{epr.county.name} - #{epr.party.abbreviation}: CD=#{epr.percentage_cd}%, Senate=#{epr.percentage_senate}%"
      end

      epr.update!(
         percentage_cd: percentage_cd,
         percentage_senate: percentage_senate
        )
    end
  end

  def find_party_votes(candidates, party_name)
    candidate = candidates.find { |c| c["candidate"] == party_name }
    candidate ? candidate["votes"].to_i : 0
  end

  def calculate_thresholds
    puts "Calculating thresholds..."

    @qualified_parties_cd = @party_votes_cd.select do |code, votes|
      percentage = (votes.to_f / @total_votes_cd * 100)
      qualified = percentage >= THRESHOLD
      puts "Party #{code}: #{percentage.round(2)}% CD (#{qualified ? 'Qualified' : 'Not Qualified'})"
      qualified
    end.keys

    @qualified_parties_senate = @party_votes_senate.select do |code, votes|
      percentage = (votes.to_f / @total_votes_senate * 100)
      qualified = percentage >= THRESHOLD
      puts "Party #{code}: #{percentage.round(2)}% Senate (#{qualified ? 'Qualified' : 'Not Qualified'})"
      qualified
    end.keys
  end

  def allocate_mandates
    puts "Allocating mandates..."

    County.find_each do |county|
      puts "Processing mandates for #{county.name}"

      @mandates_by_county[county.id] = {
        cd: calculate_county_mandates(county, :cd),
        senate: calculate_county_mandates(county, :senate)
      }

      save_county_mandates(county)
    end
  end

  def calculate_county_mandates(county, chamber)
    results = election_results_for_county(county)
    return {} if results.empty?

    qualified_parties = chamber == :cd ? @qualified_parties_cd : @qualified_parties_senate
    total_seats = if chamber == :cd
                    county.seats_for_election(@election)[:deputy]
    else
                    county.seats_for_election(@election)[:senate]
    end

    return {} if total_seats.nil? || total_seats.zero?

    # D'Hondt method
    seats_allocated = 0
    party_mandates = Hash.new(0)

    while seats_allocated < total_seats
      max_quotient = 0
      selected_party = nil

      results.each do |party_name, votes|
        next unless qualified_parties.include?(party_name)
        votes_for_chamber = chamber == :cd ? votes[:cd] : votes[:senate]
        quotient = votes_for_chamber.to_f / (party_mandates[party_name] + 1)

        if quotient > max_quotient
          max_quotient = quotient
          selected_party = party_name
        end
      end

      break unless selected_party
      party_mandates[selected_party] += 1
      seats_allocated += 1
    end

    puts "#{county.name} #{chamber.upcase} mandates: #{party_mandates.inspect}"
    party_mandates
  end

  def election_results_for_county(county)
    results = {}
    ElectionPartyResult.where(election: @election, county: county).each do |result|
      next unless result.votes_cd > 0 || result.votes_senate > 0

      party_name = result.party.name
      results[party_name] = {
        cd: result.votes_cd,
        senate: result.votes_senate
      }
    end
    results
  end

  def save_county_mandates(county)
    @mandates_by_county[county.id].each do |chamber, mandates|
      mandates.each do |party_name, seats|
        puts "Mandate for: " + party_name
        party = Party.find_by(name: party_name)
        unless party
          puts "PARTY NOT FOUND " + party_name
          next
        end

        [
          ElectionPartyCountyResult.find_or_initialize_by(
            election: @election,
            county: county,
            party: party
          ),
          ElectionPartyResult.find_or_initialize_by(
            election: @election,
            county: county,
            party: party
          )
        ].each do |result|
          if chamber == :cd
            result.update!(deputy_mandates: seats)
          else
            result.update!(senate_mandates: seats)
          end
        end
      end
    end
  end

  def save_county_result(county, party, cd_votes, senate_votes)
    result = ElectionPartyResult.find_or_create_by!(
      election: @election,
      county: county,
      party: party
    )

    result.update!(
      votes_cd: cd_votes,
      votes_senate: senate_votes
    )
  end

  def process_national_results(data)
    puts "Processing national results..."
    cd_data = data["CD"]["RO"]["candidates"]
    senate_data = data["S"]["RO"]["candidates"]

    cd_total = cd_data.sum { |c| c["votes"].to_i }
    senate_total = senate_data.sum { |c| c["votes"].to_i }

    cd_data.each do |candidate|
      next unless candidate["id"]&.start_with?("P")
      party_code = candidate["candidate"]
      party = Party.find_by(name: party_code)

      unless party
        puts "PARTY NOT FOUND " + party_code
        next
      end

      senate_votes = find_party_votes(senate_data, party_code)
      cd_votes = candidate["votes"].to_i

      result = ElectionPartyNationalResult.find_or_create_by!(
        election: @election,
        party: party
      )

      result.update!(
        votes_cd: cd_votes,
        votes_senate: senate_votes,
        percentage_cd: calculate_percentage(cd_votes, cd_total),
        percentage_senate: calculate_percentage(senate_votes, senate_total)
      )

      puts "National #{party.abbreviation}: CD=#{cd_votes}(#{result.percentage_cd}%), Senate=#{senate_votes}(#{result.percentage_senate}%)"
    end
  end

  def calculate_percentage(votes, total)
    return 0.0 if total.zero?
    value = (votes.to_f / total * 100).round(2)
    value
  end

  def log_processing_results
    puts "\nProcessing Summary:"
    puts "Total CD Votes: #{@total_votes_cd}"
    puts "Total Senate Votes: #{@total_votes_senate}"
    puts "County Results: #{ElectionPartyResult.count}"
    puts "National Results: #{ElectionPartyNationalResult.count}"
    # puts "County Mandate Allocations: #{ElectionPartyCountyResult.count}"
    puts "Qualified Parties CD: #{@qualified_parties_cd.join(', ')}"
    puts "Qualified Parties Senate: #{@qualified_parties_senate.join(', ')}"
  end
end
