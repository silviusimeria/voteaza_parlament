class Party < ApplicationRecord
  has_many :candidate_nominations
  has_many :counties, through: :candidate_nominations
  has_many :party_links

  has_many :party_memberships
  has_many :members, through: :party_memberships, source: :person

  validates :name, presence: true, uniqueness: true

  accepts_nested_attributes_for :party_links, allow_destroy: true

  def self.ransackable_attributes(auth_object = nil)
    %w[id name color logo_url website abbreviation created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[candidate_nominations abbreviation counties party_links]
  end
end
