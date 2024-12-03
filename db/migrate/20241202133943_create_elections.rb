class CreateElections < ActiveRecord::Migration[8.0]
  def change
    create_table :elections do |t|
      t.string :name, null: false
      t.string :kind, null: false # parliament, local, eu, etc
      t.date :election_date, null: false
      t.boolean :active, default: false
      t.timestamps

      t.index :kind
      t.index :election_date
      t.index :active
    end
  end
end
