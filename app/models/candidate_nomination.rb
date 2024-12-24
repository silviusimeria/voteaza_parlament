class CandidateNomination < ApplicationRecord
  include Sluggable

  belongs_to :election
  belongs_to :party
  belongs_to :county
  belongs_to :person

  validates :election, presence: true
  validates :position, presence: true,
            numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { scope: [ :name, :county_id, :party_id, :kind ] }
  validates :name, :kind, :position, presence: true
  validates :kind, presence: true, inclusion: { in: %w[senate deputy] }
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: [ :election_id, :county_id, :party_id ] }

  has_many :parliamentary_group_memberships
  has_many :parliamentary_groups, through: :parliamentary_group_memberships

  scope :for_election, ->(election) { where(election: election) }
  scope :senate, -> { where(kind: "senate") }
  scope :deputy, -> { where(kind: "deputy") }
  scope :by_position, -> { order(:position) }
  scope :qualified, -> { where(qualified: true) }

  enum :kind, {
    senate: "senate",
    deputy: "deputy"
  }

  def self.ransackable_attributes(auth_object = nil)
    %w[id name kind position county_id party_id person_id created_at updated_at qualified mandate_started election_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[person county party election]
  end
end
