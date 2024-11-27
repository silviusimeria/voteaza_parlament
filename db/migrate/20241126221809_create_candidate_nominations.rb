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
  end
end
