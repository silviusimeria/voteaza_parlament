class PartyWithCandidates
  attr_reader :party, :candidates

  def initialize(party, candidates)
    @party = party
    @candidates = candidates
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
end
