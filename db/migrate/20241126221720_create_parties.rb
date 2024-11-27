class CreateParties < ActiveRecord::Migration[8.0]
  def change
    create_table :parties do |t|
      t.string :name
      t.string :color
      t.string :logo_url

      t.timestamps
    end
  end
end
