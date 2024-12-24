class SearchService
  def initialize(term)
    @original_term = term
    @term =  term.downcase
                 .gsub("ș", "s").gsub("ț", "t") # Handle Romanian special cases first
                 .gsub("ă", "a").gsub("â", "a").gsub("î", "i")
                 .gsub(/[^a-z0-9\s-]/, "") # remove non-alphanumeric except spaces and hyphens
                 .gsub(/\s+/, "-")         # replace spaces with hyphens
                 .gsub(/-+/, "-")          # collapse multiple hyphens
                 .gsub(/^-|-$/, "")        # trim hyphens from ends
  end

  def search
    {
      parties: search_parties,
      candidates: search_candidates,
      counties: search_counties
    }
  end

  private

  def search_parties
    Party.where("slug LIKE :term OR LOWER(abbreviation) LIKE :term",
                term: "%#{@term}%")
  end

  def search_candidates
    CandidateNomination.where("slug LIKE :term OR name LIKE :original_term", term: "%#{@term}%", original_term: "%#{@original_term}%")
  end

  def search_counties
    County.where("slug LIKE :term", term: "%#{@term}%")
  end
end
