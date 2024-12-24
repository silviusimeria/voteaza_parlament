class DropCandidateLinks < ActiveRecord::Migration[7.1]
  def up
    drop_table :candidate_links
  end

  def down
    create_table :candidate_links do |t|
      t.references :candidate_nomination, null: false, foreign_key: true
      t.string :kind
      t.string :url

      t.timestamps
    end

    add_index :candidate_links, [ :candidate_nomination_id, :kind ]
  end
end
