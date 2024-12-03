class RemoveFieldsFromElectionPartCountyResults < ActiveRecord::Migration[8.0]
  def change
    remove_column :election_party_county_results, :votes
    remove_column :election_party_county_results, :percentage
  end
end
