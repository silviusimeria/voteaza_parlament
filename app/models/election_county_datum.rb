class ElectionCountyDatum < ApplicationRecord
  belongs_to :election
  belongs_to :county

  validates :election_id, uniqueness: { scope: :county_id }
  validates :senate_seats,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true
  validates :deputy_seats,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true
  validates :registered_voters,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true
end
