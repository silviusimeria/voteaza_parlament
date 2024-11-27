class County < ApplicationRecord
  has_many :candidate_nominations
  has_many :parties, through: :candidate_nominations

  validates :name, :code, :geojson_id, presence: true

  def parties_with_candidates
    candidate_nominations.includes(:party)
              .group_by(&:party)
              .map { |party, candidates| PartyWithCandidates.new(party, candidates) }
              .sort_by { |pwc| -pwc.candidates.count }
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[id name code geojson_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[candidate_nominations parties]
  end
end
