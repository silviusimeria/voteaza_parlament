class AddFunkyDataToPeople < ActiveRecord::Migration[7.1]
  def change
    add_column :people, :funky_data, :jsonb
    add_index :people, :funky_data, using: :gin
  end
end
