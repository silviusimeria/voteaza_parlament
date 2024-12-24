class CreateSenateStructure < ActiveRecord::Migration[8.0]
  def change
    create_table :senate_mandates do |t|
      t.references :election, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.string :slug
      t.boolean :active, default: false

      t.timestamps
    end

    add_index :senate_mandates, :slug, unique: true
    add_index :senate_mandates, :active

    create_table :parliamentary_groups do |t|
      t.references :senate_mandate, null: false, foreign_key: true
      t.references :party, foreign_key: true  # Can be null for independents
      t.string "name", null: false
      t.string "short_name"
      t.string "slug"
      t.string "official_id"  # For linking with external systems

      t.timestamps
    end

    add_index :parliamentary_groups, [ :senate_mandate_id, :slug ], unique: true

    create_table :parliamentary_group_memberships do |t|
      t.references :parliamentary_group, null: false, foreign_key: true
      t.references :candidate_nomination, null: false, foreign_key: true
      t.string :role  # leader, vice_leader, secretary, member
      t.string :official_id

      t.timestamps
    end

    add_index :parliamentary_group_memberships,
              [ :parliamentary_group_id, :candidate_nomination_id ],
              unique: true,
              name: 'idx_unique_group_membership'

    create_table :permanent_bureau_memberships do |t|
      t.references :senate_mandate, null: false, foreign_key: true
      t.references :candidate_nomination, null: false, foreign_key: true
      t.string :role, null: false  # president, vice_president, secretary, quaestor
      t.string :official_id

      t.timestamps
    end

    add_index :permanent_bureau_memberships,
              [ :senate_mandate_id, :candidate_nomination_id ],
              unique: true,
              name: 'idx_unique_bureau_membership'
  end
end
