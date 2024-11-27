class CreateCandidateLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :candidate_links do |t|
      t.references :candidate_nomination, null: false, foreign_key: true
      t.string :url
      t.string :kind

      t.timestamps
    end
  end
end
