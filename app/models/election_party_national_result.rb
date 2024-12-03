class ElectionPartyNationalResult < ApplicationRecord
  belongs_to :election
  belongs_to :party

  validates :votes_cd, :votes_senate,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :percentage_cd, :percentage_senate,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true
end