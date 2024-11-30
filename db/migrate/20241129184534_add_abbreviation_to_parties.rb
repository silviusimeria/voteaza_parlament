class AddAbbreviationToParties < ActiveRecord::Migration[8.0]
  def change
    add_column :parties, :abbreviation, :string
    add_column :parties, :description, :text
  end
end
