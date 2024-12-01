class AddSlugToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :slug, :string

    add_index :people, :slug
  end
end
