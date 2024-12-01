class AddSlugsToTables < ActiveRecord::Migration[8.0]
  def change
    add_column :parties, :slug, :string
    add_column :candidate_nominations, :slug, :string
    add_column :counties, :slug, :string

    add_index :parties, :slug
    add_index :candidate_nominations, :slug
    add_index :counties, :slug
  end
end
