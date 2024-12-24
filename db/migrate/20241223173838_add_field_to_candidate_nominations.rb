class AddFieldToCandidateNominations < ActiveRecord::Migration[8.0]
  def change
    add_column :candidate_nominations, :mandate_allocated, :boolean, default: false
    add_column :candidate_nominations, :mandate_started, :boolean, default: false
    add_column :candidate_nominations, :mandate_start_date, :date
  end
end
