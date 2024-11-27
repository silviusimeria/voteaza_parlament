class CreateCandidateNominations < ActiveRecord::Migration[8.0]
  def change
    create_table :candidate_nominations do |t|
      t.references :county, null: false, foreign_key: true
      t.references :party, null: false, foreign_key: true
      t.string :name
      t.string :kind
      t.integer :position

      t.timestamps
    end
    add_index :candidate_nominations, [ :county_id, :party_id, :kind, :position ],
              unique: true,
              name: 'idx_nominations_unique_position'
  end
end
