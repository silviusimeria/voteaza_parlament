class AddParliamentSeatsToCounties < ActiveRecord::Migration[8.0]
  def change
    add_column :counties, :senate_seats, :integer, default: 0
    add_column :counties, :deputy_seats, :integer, default: 0
  end
end
