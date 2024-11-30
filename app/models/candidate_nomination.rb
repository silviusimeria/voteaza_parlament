class CandidateNomination < ApplicationRecord
  belongs_to :county
  belongs_to :party
  has_many :candidate_links
  belongs_to :person, optional: true

  accepts_nested_attributes_for :candidate_links, allow_destroy: true

  validates :name, :kind, :position, presence: true
  validates :position, uniqueness: { scope: [ :name, :county_id, :party_id, :kind ] }

  enum :kind, {
    senate: "senate",
    deputy: "deputy"
  }

  def self.ransackable_attributes(auth_object = nil)
    %w[id name kind position county_id party_id person_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[person county party candidate_links]
  end
end
