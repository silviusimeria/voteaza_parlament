class PartyWithCandidates
  attr_reader :party, :candidates, :votes, :mandates

  def initialize(party, candidates, votes, mandates)
    @party = party
    @candidates = candidates
    @votes = votes
    @mandates = mandates
  end

  def name
    party.name
  end

  def slug
    party.slug
  end

  def color
    party.color
  end

  def logo_url
    party.logo_url
  end

  def abbreviation
    party.abbreviation
  end

  def party_links
    party.party_links
  end

  def senate_percentage
    votes&.percentage_senate || 0
  end

  def deputy_percentage
    votes&.percentage_cd || 0
  end

  def senate_mandates
    mandates&.senate_mandates || 0
  end

  def deputy_mandates
    mandates&.deputy_mandates || 0
  end
end
