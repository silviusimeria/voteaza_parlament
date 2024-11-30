class MigrateCandidateDataToPeople < ActiveRecord::Migration[8.0]
  def up
    # Create a person for each candidate
    execute <<-SQL
      INSERT INTO people (name, created_at, updated_at)
      SELECT name, created_at, updated_at
      FROM candidate_nominations
    SQL

    # Link candidates to their person records
    execute <<-SQL
      UPDATE candidate_nominations
      SET person_id = people.id 
      FROM people 
      WHERE candidate_nominations.name = people.name
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
