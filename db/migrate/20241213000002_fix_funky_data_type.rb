class FixFunkyDataType < ActiveRecord::Migration[8.0]
  def up
    remove_index :people, :funky_data if index_exists?(:people, :funky_data)
    change_column :people, :funky_data, :jsonb
    add_index :people, :funky_data, using: :gin
  end

  def down
    remove_index :people, :funky_data if index_exists?(:people, :funky_data)
    change_column :people, :funky_data, :json
    add_index :people, :funky_data
  end
end
