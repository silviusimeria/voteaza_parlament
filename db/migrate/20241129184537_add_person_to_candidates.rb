class AddPersonToCandidates < ActiveRecord::Migration[8.0]
  def change
    add_reference :candidate_nominations, :person, foreign_key: true
  end
end
