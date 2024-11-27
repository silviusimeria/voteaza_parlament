class Party < ApplicationRecord
  has_many :candidate_nominations
  has_many :counties, through: :candidate_nominations
  has_many :party_links

  validates :name, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    %w[id name color logo_url website created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[candidate_nominations counties party_links]
  end
end
