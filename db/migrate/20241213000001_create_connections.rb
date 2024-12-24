class CreateConnections < ActiveRecord::Migration[8.0]
  def change
    create_table :connections do |t|
      t.references :person, null: false
      t.references :connected_person, null: false
      t.string :relationship_type, null: false
      t.string :source_url
      t.string :source_text
      t.timestamps

    end

    add_index :connections, [:person_id, :connected_person_id, :relationship_type], unique: true, name: 'idx_unique_connections'
  end
end