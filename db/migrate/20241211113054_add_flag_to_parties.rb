class AddFlagToParties < ActiveRecord::Migration[8.0]
  def change
    add_column :parties, :minority, :boolean, default: false
    add_index :parties, :minority
  end
end
