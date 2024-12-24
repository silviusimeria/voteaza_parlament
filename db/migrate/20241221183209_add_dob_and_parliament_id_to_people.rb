class AddDobAndParliamentIdToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :dob, :date
    add_column :people, :parliament_id, :string
    add_index :people, :parliament_id
  end
end
