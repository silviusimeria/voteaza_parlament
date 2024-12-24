class NationalMandateAllocation
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
    allocate_county_mandates
    allocate_remaining_mandates
    # save_results
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
    [ :cd, :senate ].each do |chamber|
      votes_field = "votes_#{chamber}"
      total_votes = ElectionPartyResult.where(election: @election).sum(votes_field)

      Party.find_each do |party|
        party_votes = ElectionPartyResult.where(election: @election, party: party).sum(votes_field)
        percentage = (party_votes.to_f / total_votes * 100)

        if percentage >= THRESHOLD
          @parties_above_threshold[chamber] << party.id
        end
      end
    end
  end

  def allocate_county_mandates
    County.find_each do |county|
      [ :cd, :senate ].each do |chamber|
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

    results.each do |result|
      votes = result.send(votes_field)
      if votes >= electoral_coefficient
        # Calculate how many complete coefficients fit into votes
        direct_mandates = (votes / electoral_coefficient).floor
        remainder = votes % electoral_coefficient

        # Store remainder for national redistribution
        @remaining_votes[chamber][result.party_id] ||= 0
        @remaining_votes[chamber][result.party_id] += remainder

        # Allocate direct mandates
        result = ElectionPartyCountyResult.find_or_create_by!(
          election: @election,
          county: county,
          party_id: result.party_id
        )

        if chamber == :cd
          result.update!(deputy_mandates: direct_mandates)
        else
          result.update!(senate_mandates: direct_mandates)
        end
      else
        # All votes go to national redistribution
        @remaining_votes[chamber][result.party_id] ||= 0
        @remaining_votes[chamber][result.party_id] += votes
      end
    end
  end

  def distribute_remaining_mandates(mandates, chamber)
    mandates.each do |party_id, total_seats|
      remaining_seats = total_seats

      while remaining_seats > 0
        # Find counties where additional mandates can be allocated
        best_county = ElectionPartyResult
                        .joins(<<-SQL)
          LEFT JOIN election_party_county_results epcr ON#{' '}
          epcr.election_id = election_party_results.election_id AND
          epcr.county_id = election_party_results.county_id AND
          epcr.party_id = election_party_results.party_id
        SQL
                        .where(election: @election, party_id: party_id)
                        .where(<<-SQL, chamber == :cd ? "deputy" : "senate")
          (
            SELECT COALESCE(SUM(#{chamber == :cd ? 'deputy' : 'senate'}_mandates), 0)
            FROM election_party_county_results
            WHERE election_id = #{@election.id}
            AND county_id = election_party_results.county_id
          ) < (
            SELECT #{chamber == :cd ? 'deputy' : 'senate'}_seats
            FROM election_county_data
            WHERE election_id = #{@election.id}
            AND county_id = election_party_results.county_id
          )
        SQL
                        .order("election_party_results.votes_#{chamber} DESC")
                        .first

        break unless best_county

        county_result = ElectionPartyCountyResult.find_or_create_by!(
          election: @election,
          county: best_county.county,
          party_id: party_id
        )

        if chamber == :cd
          county_result.update!(deputy_mandates: county_result.deputy_mandates.to_i + 1)
        else
          county_result.update!(senate_mandates: county_result.senate_mandates.to_i + 1)
        end

        remaining_seats -= 1
      end
    end
  end

  def allocate_county_seats(votes, total_seats, chamber, county)
    return if votes.empty?

    mandates = dhondt_allocation(votes, total_seats)
    mandates.each do |party_id, seats|
      @allocated_mandates[chamber][party_id] ||= 0
      @allocated_mandates[chamber][party_id] += seats

      result = ElectionPartyCountyResult.find_or_create_by!(
        election: @election,
        county: county,
        party_id: party_id
      )

      if chamber == :cd
        result.update!(deputy_mandates: seats)
      else
        result.update!(senate_mandates: seats)
      end
    end
  end

  def allocate_remaining_mandates
    [ :cd, :senate ].each do |chamber|
      allocated = @allocated_mandates[chamber].values.sum
      remaining = @total_mandates[chamber] - allocated

      puts "\nProcessing #{chamber.upcase} remaining mandates"
      puts "Total mandates: #{@total_mandates[chamber]}"
      puts "Already allocated: #{allocated}"
      puts "Remaining to allocate: #{remaining}"
      puts "\nRemaining votes by party:"

      @remaining_votes[chamber].each do |party_id, votes|
        party = Party.find(party_id)
        puts "#{party.name}: #{votes}"
      end

      # Calculate national electoral number
      votes_sums = @remaining_votes[chamber].map do |party_id, votes|
        [ party_id, votes ]
      end

      # Divide sequentially and sort by results
      quotients = []
      votes_sums.each do |party_id, votes|
        1.upto(remaining) do |i|
          quotients << {
            party_id: party_id,
            value: votes.to_f / i,
            original_votes: votes
          }
        end
      end

      # Sort by quotient value, use original votes as tiebreaker
      quotients.sort_by! { |q| [ -q[:value], -q[:original_votes] ] }

      # Take top quotients up to remaining seats
      mandates = quotients.first(remaining).group_by { |q| q[:party_id] }
                          .transform_values(&:count)

      distribute_remaining_mandates(mandates, chamber)

      puts "\nFinal mandate distribution:"
      mandates.each do |party_id, count|
        party = Party.find(party_id)
        puts "#{party.name}: #{count}"
      end
    end
  end

  def dhondt_allocation(votes, seats)
    mandates = Hash.new(0)
    seats.times do
      max_quotient = 0
      selected_party = nil

      votes.each do |party_id, vote_count|
        quotient = vote_count.to_f / (mandates[party_id] + 1)
        if quotient > max_quotient
          max_quotient = quotient
          selected_party = party_id
        end
      end

      break unless selected_party
      mandates[selected_party] += 1
    end

    mandates
  end

  def save_results
    Party.find_each do |party|
      national_result = ElectionPartyNationalResult.find_or_create_by!(
        election: @election,
        party: party
      )

      cd_mandates = ElectionPartyCountyResult.where(election: @election, party: party).sum(:deputy_mandates)
      senate_mandates = ElectionPartyCountyResult.where(election: @election, party: party).sum(:senate_mandates)

      national_result.update!(
        total_mandates_cd: cd_mandates,
        total_mandates_senate: senate_mandates
      )
    end
  end

  def print_final_stats
    total_cd = ElectionPartyCountyResult.where(election: @election).sum(:deputy_mandates)
    total_senate = ElectionPartyCountyResult.where(election: @election).sum(:senate_mandates)

    text = []
    Party.find_each do |party|
      cd = ElectionPartyCountyResult.where(election: @election, party: party).sum(:deputy_mandates)
      senate = ElectionPartyCountyResult.where(election: @election, party: party).sum(:senate_mandates)
      next if cd.zero? && senate.zero?
      text <<  "#{party.name}: CD=#{cd}, Senate=#{senate}"
    end

    puts "\n=== Final allocation statistics ==="
    puts "Total CD mandates allocated: #{total_cd}"
    puts "Total Senate mandates allocated: #{total_senate}"
    puts "\nBy party:"
    puts text
  end
end
