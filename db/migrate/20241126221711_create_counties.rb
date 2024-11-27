class CreateCounties < ActiveRecord::Migration[8.0]
  def change
    create_table :counties do |t|
      t.string :name
      t.string :code
      t.string :geojson_id

      t.timestamps
    end
    add_index :counties, :code, unique: true
  end
end
