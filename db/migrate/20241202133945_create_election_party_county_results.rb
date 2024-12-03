class CreateElectionPartyCountyResults < ActiveRecord::Migration[8.0]
  def change
    create_table :election_party_county_results do |t|
      t.references :election, null: false, foreign_key: true
      t.references :party, null: false, foreign_key: true
      t.references :county, null: false, foreign_key: true
      t.integer :votes, null: false
      t.decimal :percentage, precision: 5, scale: 2, null: false
      t.integer :senate_mandates
      t.integer :deputy_mandates
      t.timestamps

      t.index [:election_id, :party_id, :county_id],
              unique: true,
              name: 'idx_election_party_county'
    end
  end
end
