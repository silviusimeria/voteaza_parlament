class CreatePeopleLinks < ActiveRecord::Migration[7.1]
  def change
    create_table :people_links do |t|
      t.references :person, null: false, foreign_key: true
      t.string :kind
      t.string :url
      t.boolean :official, default: false

      t.timestamps
    end

    add_index :people_links, [:person_id, :kind]
  end
end