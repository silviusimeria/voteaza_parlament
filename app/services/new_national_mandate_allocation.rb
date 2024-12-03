class NewNationalMandateAllocation
  THRESHOLD = 5.0

  def initialize(election)
    @election = election
    @parties_above_threshold = { cd: [], senate: [] }
    @remaining_votes = { cd: {}, senate: {} }
    @allocated_mandates = { cd: {}, senate: {} }
    @total_mandates = {
      cd: calculate_total_seats(:deputy),
      senate: calculate_total_seats(:senate)
    }
  end

  def allocate
    clear_existing_mandates
    identify_qualifying_parties
    allocate_county_stage
    allocate_national_stage
    print_final_stats
  end

  private

  def clear_existing_mandates
    puts "Clearing existing mandates..."
    ElectionPartyCountyResult.where(election: @election).update_all(
      deputy_mandates: 0,
      senate_mandates: 0
    )
  end

  def calculate_total_seats(type)
    ElectionCountyDatum.where(election: @election).sum("#{type}_seats")
  end

  def identify_qualifying_parties
    [:cd, :senate].each do |chamber|
      votes_field = "votes_#{chamber}"
      total_votes = ElectionPartyResult.where(election: @election).sum(votes_field)

      Party.find_each do |party|
        party_votes = ElectionPartyResult.where(election: @election, party: party).sum(votes_field)
        percentage = (party_votes.to_f / total_votes * 100)

        if percentage >= THRESHOLD
          @parties_above_threshold[chamber] << party.id
          puts "#{party.name} qualifies for #{chamber} with #{percentage.round(2)}%"
        end
      end
    end
  end

  def allocate_county_stage
    puts "\nAllocating county stage..."
    County.find_each do |county|
      [:cd, :senate].each do |chamber|
        process_county_chamber(county, chamber)
      end
    end
  end

  def process_county_chamber(county, chamber)
    seats = chamber == :cd ? county.seats_for_election(@election)[:deputy] : county.seats_for_election(@election)[:senate]
    return if seats.zero?

    votes_field = "votes_#{chamber}"
    results = ElectionPartyResult.where(
      election: @election,
      county: county,
      party_id: @parties_above_threshold[chamber]
    )

    total_votes = results.sum(votes_field)
    return if total_votes.zero?

    electoral_coefficient = total_votes.to_f / seats
    puts "\nProcessing #{county.name} for #{chamber.upcase}"
    puts "Electoral coefficient: #{electoral_coefficient.round(2)}"

    results.each do |result|
      votes = result.send(votes_field)
      direct_mandates = (votes / electoral_coefficient).floor
      remainder = votes % electoral_coefficient

      @remaining_votes[chamber][result.party_id] ||= 0
      @remaining_votes[chamber][result.party_id] += remainder

      if direct_mandates > 0
        result = ElectionPartyCountyResult.find_or_create_by!(
          election: @election,
          county: county,
          party_id: result.party_id
        )

        mandate_field = chamber == :cd ? :deputy_mandates : :senate_mandates
        result.update!(mandate_field => direct_mandates)

        party = Party.find(result.party_id)
        puts "#{party.name}: #{direct_mandates} direct mandates, remainder #{remainder.round(2)}"
      else
        @remaining_votes[chamber][result.party_id] ||= 0
        @remaining_votes[chamber][result.party_id] += votes
      end
    end
  end

  def allocate_national_stage
    [:cd, :senate].each do |chamber|
      allocated = ElectionPartyCountyResult.where(election: @election)
                                           .sum(chamber == :cd ? :deputy_mandates : :senate_mandates)
      remaining = @total_mandates[chamber] - allocated

      puts "\nProcessing #{chamber.upcase} national redistribution"
      puts "Already allocated: #{allocated}"
      puts "Remaining to allocate: #{remaining}"

      distribute_remaining_mandates(remaining, chamber)
    end
  end

  def distribute_remaining_mandates(remaining_seats, chamber)
    return if remaining_seats <= 0

    quotients = []
    @remaining_votes[chamber].each do |party_id, votes|
      1.upto(remaining_seats) do |i|
        quotients << {
          party_id: party_id,
          value: votes.to_f / i,
          original_votes: votes
        }
      end
    end

    quotients.sort_by! { |q| [-q[:value], -q[:original_votes]] }
    mandates = quotients.first(remaining_seats).group_by { |q| q[:party_id] }
                        .transform_values(&:count)

    puts "\nNational redistribution mandates:"
    mandates.each do |party_id, count|
      party = Party.find(party_id)
      puts "#{party.name}: #{count}"
    end

    allocate_to_counties(mandates, chamber)
  end

  def allocate_to_counties(mandates, chamber)
    mandates.each do |party_id, count|
      remaining = count
      while remaining > 0
        county = find_best_county_for_mandate(party_id, chamber)
        break unless county

        result = ElectionPartyCountyResult.find_or_create_by!(
          election: @election,
          county: county,
          party_id: party_id
        )

        if chamber == :cd
          result.update!(deputy_mandates: result.deputy_mandates.to_i + 1)
        else
          result.update!(senate_mandates: result.senate_mandates.to_i + 1)
        end

        remaining -= 1
      end
    end
  end

  def find_best_county_for_mandate(party_id, chamber)
    mandate_field = chamber == :cd ? 'deputy_mandates' : 'senate_mandates'
    seats_field = chamber == :cd ? 'deputy_seats' : 'senate_seats'
    votes_field = "votes_#{chamber}"

    available_counties = County.joins(:election_county_data)
                               .where("election_county_data.election_id = ? AND election_county_data.#{seats_field} > 0", @election.id)
                               .select("counties.*, election_county_data.#{seats_field}")

    available_counties = available_counties.reject do |county|
      allocated = ElectionPartyCountyResult.where(election: @election, county: county)
                                           .sum(mandate_field)
      allocated >= county.send(seats_field)
    end

    return nil if available_counties.empty?

    # Get total votes per county
    county_totals = ElectionPartyResult.where(
      election: @election,
      county_id: available_counties.map(&:id)
    ).group(:county_id).sum(votes_field)

    # Get party results for these counties
    results = ElectionPartyResult.where(
      election: @election,
      party_id: party_id,
      county_id: available_counties.map(&:id)
    ).index_by(&:county_id)

    county_scores = available_counties.map do |county|
      result = results[county.id]
      next unless result

      allocated = ElectionPartyCountyResult.find_by(
        election: @election,
        county: county,
        party_id: party_id
      )&.send(mandate_field) || 0

      total_allocated = ElectionPartyCountyResult.where(
        election: @election,
        county: county
      ).sum(mandate_field)

      remaining_seats = county.send(seats_field) - total_allocated
      total_votes = county_totals[county.id] || 0
      vote_share = total_votes > 0 ? result.send(votes_field).to_f / total_votes : 0
      seats_ratio = county.send(seats_field) > 0 ? allocated.to_f / county.send(seats_field) : 0

      {
        county: county,
        vote_weight: result.send(votes_field),
        vote_share: vote_share,
        remaining_seats: remaining_seats,
        seats_ratio: seats_ratio,
        final_score: calculate_county_score(vote_share, seats_ratio, remaining_seats)
      }
    end.compact

    return nil if county_scores.empty?

    county_scores.max_by { |score| score[:final_score] }[:county]
  end

  def calculate_county_score(vote_share, seats_ratio, remaining_seats)
    # Weight factors
    vote_weight = 0.7
    seats_weight = 0.2
    remaining_weight = 0.1

    # Boost score for high vote share counties
    vote_boost = vote_share > 0.3 ? 1.5 : 1.0

    # Normalize seats ratio inverse (prefer counties where party has fewer seats relative to total)
    inverse_seats_ratio = 1 - seats_ratio

    # Calculate weighted score + boost
    (vote_share * vote_weight * vote_boost) +
      ((1 - seats_ratio) * seats_weight) +
      (remaining_seats * remaining_weight)
  end

  def print_final_stats
    total_cd = ElectionPartyCountyResult.where(election: @election).sum(:deputy_mandates)
    total_senate = ElectionPartyCountyResult.where(election: @election).sum(:senate_mandates)

    puts "\n=== Final allocation statistics ==="
    puts "Total CD mandates allocated: #{total_cd}"
    puts "Total Senate mandates allocated: #{total_senate}"
    puts "\nBy party:"

    Party.find_each do |party|
      cd = ElectionPartyCountyResult.where(election: @election, party: party).sum(:deputy_mandates)
      senate = ElectionPartyCountyResult.where(election: @election, party: party).sum(:senate_mandates)
      next if cd.zero? && senate.zero?
      puts "#{party.name}: CD=#{cd}, Senate=#{senate}"
    end
  end
end