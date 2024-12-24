class MandateAllocationService
  NATIONAL_THRESHOLD = 5.0

  def initialize(election)
    @election = election
    @parties_above_threshold = { cd: [], senate: [] }
    @unallocated_seats = { cd: 0, senate: 0 }
    @remaining_votes = { cd: {}, senate: {} }
  end

  def process
    puts "\n=== Starting mandate allocation process ==="
    clear_existing_mandates
    identify_parties_above_threshold
    allocate_county_mandates
    allocate_remaining_mandates
    print_final_stats
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
        total_seats = chamber == :cd ? seats[:deputy] : seats[:senate]
        next if total_seats.to_i.zero?

        county_threshold = 100.0 / total_seats
        puts "\n#{chamber.upcase} Chamber (#{total_seats} seats, threshold: #{county_threshold.round(2)}%)"

        results = ElectionPartyResult.where(
          election: @election,
          county: county,
          party_id: @parties_above_threshold[chamber]
        )

        votes_field = "votes_#{chamber}"
        total_county_votes = results.sum(votes_field)
        qualified_votes = {}

        results.each do |result|
          votes = result.send(votes_field)
          percentage = (votes.to_f / total_county_votes * 100).round(2)
          puts "#{result.party.name}: #{votes} votes (#{percentage}%)"

          if percentage >= county_threshold
            qualified_votes[result.party_id] = votes
            puts "  ✓ Above county threshold"
          else
            @remaining_votes[chamber][result.party_id] ||= 0
            @remaining_votes[chamber][result.party_id] += votes
            puts "  × Below county threshold - added to remaining pool"
          end
        end

        if qualified_votes.any?
          mandates = dhondt_allocation(qualified_votes, total_seats)
          puts "\nAllocated mandates:"
          mandates.each do |party_id, seats|
            party = Party.find(party_id)
            puts "#{party.name}: #{seats} seats"
          end

          save_county_mandates(county, mandates, chamber)
          unallocated = total_seats - mandates.values.sum
          @unallocated_seats[chamber] += unallocated
          puts "Unallocated seats: #{unallocated}"
        else
          puts "No parties qualified for mandates"
          @unallocated_seats[chamber] += total_seats
        end
      end
    end
  end

  def allocate_remaining_mandates
    puts "\n=== Allocating remaining mandates ==="
    [ :cd, :senate ].each do |chamber|
      puts "\n#{chamber.upcase} Chamber"
      puts "Unallocated seats: #{@unallocated_seats[chamber]}"
      puts "Remaining votes by party:"

      @remaining_votes[chamber].each do |party_id, votes|
        party = Party.find(party_id)
        puts "#{party.name}: #{votes} votes"
      end

      if @unallocated_seats[chamber].positive? && @remaining_votes[chamber].any?
        mandates = dhondt_allocation(@remaining_votes[chamber], @unallocated_seats[chamber])
        puts "\nAllocated remaining mandates:"
        mandates.each do |party_id, seats|
          party = Party.find(party_id)
          puts "#{party.name}: #{seats} seats"
        end

        update_with_remaining_mandates(mandates, chamber)
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

  def update_with_remaining_mandates(mandates, chamber)
    mandates.each do |party_id, additional_seats|
      seats_remaining = additional_seats

      County.find_each do |county|
        break if seats_remaining.zero?

        result = ElectionPartyResult
                   .where(election: @election, party_id: party_id, county: county)
                   .joins("LEFT JOIN election_party_county_results epcr ON
               epcr.election_id = election_party_results.election_id AND
               epcr.county_id = election_party_results.county_id AND
               epcr.party_id = election_party_results.party_id")
                   .where("epcr.#{chamber == :cd ? 'deputy' : 'senate'}_mandates = 0 OR epcr.#{chamber == :cd ? 'deputy' : 'senate'}_mandates IS NULL")
                   .order("election_party_results.votes_#{chamber} DESC")
                   .first

        next unless result

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

        seats_remaining -= 1
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
