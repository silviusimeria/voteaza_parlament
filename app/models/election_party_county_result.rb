class ElectionPartyCountyResult < ApplicationRecord
  belongs_to :election
  belongs_to :party
  belongs_to :county
end