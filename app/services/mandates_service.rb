class MandatesService
  NATIONAL_THRESHOLD = 5.0
  MINORITY_SEATS = 19

  def initialize(election)
    @election = election
    @parties_above_threshold = { cd: [], senate: [] }
    @total_seats = {
      cd: calculate_total_seats(:deputy),
      senate: calculate_total_seats(:senate)
    }
    @remaining_votes = { cd: {}, senate: {} }
    @unallocated_seats = { cd: 0, senate: 0 }
  end

  def process
    puts "\n=== Starting mandate allocation process ==="
    clear_existing_mandates
    identify_parties_above_threshold
    allocate_county_mandates
    allocate_remaining_mandates
    print_final_stats
  end

  private

  def calculate_total_seats(chamber)
    ElectionCountyDatum.where(election: @election).sum("#{chamber}_seats")
  end

  def clear_existing_mandates
    puts "Clearing existing mandates..."
    ElectionPartyCountyResult.where(election: @election).update_all(
      deputy_mandates: 0,
      senate_mandates: 0
    )
  end

  def identify_parties_above_threshold
    [ :cd, :senate ].each do |chamber|
      votes_field = "votes_#{chamber}"
      total_votes = ElectionPartyResult.where(election: @election).sum(votes_field)
      puts "\nCalculating national threshold for #{chamber.upcase}"
      puts "Total votes: #{total_votes}"

      Party.find_each do |party|
        party_votes = ElectionPartyResult.where(election: @election, party: party).sum(votes_field)
        percentage = (party_votes.to_f / total_votes * 100).round(2)
        puts "#{party.name}: #{party_votes} votes (#{percentage}%)"

        if percentage >= NATIONAL_THRESHOLD
          @parties_above_threshold[chamber] << party.id
          puts "  ✓ Above national threshold"
        else
          puts "  × Below national threshold"
        end
      end
    end
  end

  def allocate_county_mandates
    County.find_each do |county|
      puts "\nProcessing #{county.name}..."
      seats = county.seats_for_election(@election)

      [ :cd, :senate ].each do |chamber|
        total_seats = if chamber == :cd
                        seats[:deputy]
        else
                        seats[:senate]
        end
        next if total_seats.to_i.zero?

        votes_field = "votes_#{chamber}"
        results = ElectionPartyResult.where(
          election: @election,
          county: county,
          party_id: @parties_above_threshold[chamber]
        )

        total_county_votes = results.sum(votes_field)
        next if total_county_votes.zero?

        mandates = calculate_county_mandates(results, total_seats, votes_field)
        save_county_mandates(county, mandates, chamber)

        unallocated = total_seats - mandates.values.sum
        @unallocated_seats[chamber] += unallocated

        # Store remaining votes for parties that got no mandates
        results.each do |result|
          votes = result.send(votes_field)
          party_id = result.party_id

          if !mandates.key?(party_id)
            @remaining_votes[chamber][party_id] ||= 0
            @remaining_votes[chamber][party_id] += votes
          end
        end
      end
    end
  end

  def calculate_county_mandates(results, total_seats, votes_field)
    return {} if total_seats.zero?

    total_votes = results.sum(votes_field)
    votes_by_party = {}

    results.each do |result|
      votes = result.send(votes_field)
      percentage = (votes.to_f / total_votes * 100)

      # Only parties that exceed county electoral coefficient get mandates
      if percentage >= (100.0 / total_seats)
        votes_by_party[result.party_id] = votes
      end
    end

    dhondt_allocation(votes_by_party, total_seats)
  end

  def allocate_remaining_mandates
    puts "\n=== Allocating remaining mandates ==="
    [ :cd, :senate ].each do |chamber|
      unallocated = @unallocated_seats[chamber]
      next if unallocated.zero?

      puts "\n#{chamber.upcase} Chamber - #{unallocated} seats to allocate"
      total_remaining_votes = @remaining_votes[chamber].values.sum
      next if total_remaining_votes.zero?

      # Use D'Hondt for remaining mandates
      mandates = dhondt_allocation(@remaining_votes[chamber], unallocated)
      distribute_remaining_mandates(mandates, chamber)
    end
  end

  def distribute_remaining_mandates(mandates, chamber)
    mandates.each do |party_id, seat_count|
      # Find counties where this party performed best but got no mandates
      best_counties = ElectionPartyResult
                        .where(election: @election, party_id: party_id)
                        .joins("LEFT JOIN election_party_county_results epcr ON
               epcr.election_id = election_party_results.election_id AND
               epcr.county_id = election_party_results.county_id AND
               epcr.party_id = election_party_results.party_id")
                        .where("epcr.#{chamber == :cd ? 'deputy' : 'senate'}_mandates = 0 OR epcr.#{chamber == :cd ? 'deputy' : 'senate'}_mandates IS NULL")
                        .order("election_party_results.votes_#{chamber} DESC")
                        .limit(seat_count)

      best_counties.each do |result|
        county_result = ElectionPartyCountyResult.find_or_create_by!(
          election: @election,
          county: result.county,
          party_id: party_id
        )

        if chamber == :cd
          county_result.update!(deputy_mandates: county_result.deputy_mandates.to_i + 1)
        else
          county_result.update!(senate_mandates: county_result.senate_mandates.to_i + 1)
        end
      end
    end
  end

  def save_county_mandates(county, mandates, chamber)
    mandates.each do |party_id, seats|
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
