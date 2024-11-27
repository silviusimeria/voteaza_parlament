class PartyWithCandidates
  attr_reader :party, :candidates

  def initialize(party, candidates)
    @party = party
    @candidates = candidates
  end

  def name
    party.name
  end

  def color
    party.color
  end

  def link
    party.party_links.first
  end
end