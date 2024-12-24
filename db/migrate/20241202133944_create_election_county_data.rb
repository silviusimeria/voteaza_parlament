class CreateElectionCountyData < ActiveRecord::Migration[8.0]
  def change
    create_table :election_county_data do |t|
      t.references :election, null: false, foreign_key: true
      t.references :county, null: false, foreign_key: true
      t.integer :senate_seats
      t.integer :deputy_seats
      t.integer :registered_voters
      t.timestamps

      t.index [ :election_id, :county_id ], unique: true
    end
  end
end
