class CreateVoteResults < ActiveRecord::Migration[8.0]
  def change
    # Add electoral code to parties
    add_column :parties, :electoral_code, :string
    add_index :parties, :electoral_code

    # Store vote results per election/county/party
    create_table :election_party_results do |t|
      t.references :election, null: false
      t.references :county, null: false
      t.references :party, null: false
      t.integer :votes_cd, null: false, default: 0
      t.decimal :percentage_cd, precision: 5, scale: 2
      t.integer :votes_senate, null: false, default: 0
      t.decimal :percentage_senate, precision: 5, scale: 2
      t.integer :deputy_mandates
      t.integer :senate_mandates
      t.timestamps

      t.index [ :election_id, :county_id, :party_id ], unique: true, name: 'idx_election_party_results'
    end

    # Store national level results per election/party
    create_table :election_party_national_results do |t|
      t.references :election, null: false
      t.references :party, null: false
      t.integer :votes_cd, null: false, default: 0
      t.decimal :percentage_cd, precision: 5, scale: 2
      t.integer :votes_senate, null: false, default: 0
      t.decimal :percentage_senate, precision: 5, scale: 2
      t.boolean :over_threshold_cd, default: false
      t.boolean :over_threshold_senate, default: false
      t.timestamps

      t.index [ :election_id, :party_id ], unique: true
    end
  end
end
