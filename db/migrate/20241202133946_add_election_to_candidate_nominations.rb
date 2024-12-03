class AddElectionToCandidateNominations < ActiveRecord::Migration[8.0]
  def change
    add_reference :candidate_nominations, :election, foreign_key: true
  end
end
