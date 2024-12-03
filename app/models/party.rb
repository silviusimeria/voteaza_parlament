class Party < ApplicationRecord
  include Sluggable

  has_many :candidate_nominations
  has_many :counties, through: :candidate_nominations
  has_many :party_links

  has_many :party_memberships
  has_many :members, through: :party_memberships, source: :person

  has_many :election_party_county_results
  has_many :election_party_results
  has_many :candidate_nominations
  has_many :election_party_national_results

  validates :name, presence: true, uniqueness: true

  accepts_nested_attributes_for :party_links, allow_destroy: true

  def self.ransackable_attributes(auth_object = nil)
    %w[id name color logo_url website abbreviation created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[candidate_nominations abbreviation counties party_links]
  end

  def results_for_election(election)
    election_party_county_results.where(election: election)
  end

  def total_votes_for_election(election)
    results_for_election(election).sum(:votes)
  end

  def national_percentage_for_election(election)
    total_votes = election_party_county_results
                    .where(election: election)
                    .sum(:votes)

    return 0 if total_votes.zero?

    (total_votes_for_election(election).to_f / total_votes * 100).round(2)
  end
end
