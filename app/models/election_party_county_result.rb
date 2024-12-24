class ElectionPartyCountyResult < ApplicationRecord
  belongs_to :election
  belongs_to :party
  belongs_to :county

  def self.ransackable_attributes(auth_object = nil)
    %w[id election_id party_id county_id senate_mandates deputy_mandates created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[county election party]
  end
end
