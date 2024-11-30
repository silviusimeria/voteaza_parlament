class CreatePartyMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :party_memberships do |t|
      t.references :party, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.string :role
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end
