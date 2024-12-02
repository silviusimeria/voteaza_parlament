class MigrateCandidateLinksToPeopleLinks < ActiveRecord::Migration[8.0]
  def up
    # Migrate existing candidate links to people links
    execute <<-SQL
      INSERT INTO people_links (person_id, kind, url, created_at, updated_at)
      SELECT cn.person_id, cl.kind, cl.url, cl.created_at, cl.updated_at
      FROM candidate_links cl
      JOIN candidate_nominations cn ON cl.candidate_nomination_id = cn.id
      WHERE cn.person_id IS NOT NULL
    SQL
  end

  def down
    # Cannot restore deleted links
    raise ActiveRecord::IrreversibleMigration
  end
end
