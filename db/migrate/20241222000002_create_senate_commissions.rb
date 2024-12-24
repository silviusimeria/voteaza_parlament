class CreateSenateCommissions < ActiveRecord::Migration[8.0]
  def change
    create_table :senate_commissions do |t|
      t.references :senate_mandate, null: false, foreign_key: true
      t.string :name, null: false
      t.string :short_name
      t.string :slug
      t.string :commission_type  # permanent, investigation, common
      t.string :official_id  # For linking with external systems
      t.text :description
      t.datetime :investigation_start_date  # For investigation commissions
      t.datetime :investigation_end_date    # For investigation commissions
      
      t.timestamps
    end
    
    add_index :senate_commissions, [:senate_mandate_id, :slug], unique: true

    create_table :senate_commission_memberships do |t|
      t.references :senate_commission, null: false, foreign_key: true
      t.references :candidate_nomination, null: false, foreign_key: true
      t.string :role  # president, vice_president, secretary, member
      t.string :official_id
      
      t.timestamps
    end
    
    add_index :senate_commission_memberships, 
              [:senate_commission_id, :candidate_nomination_id], 
              unique: true,
              name: 'idx_unique_commission_membership'
  end
end