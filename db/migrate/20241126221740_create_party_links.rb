class CreatePartyLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :party_links do |t|
      t.references :party, null: false, foreign_key: true
      t.string :url
      t.string :kind

      t.timestamps
    end
  end
end
