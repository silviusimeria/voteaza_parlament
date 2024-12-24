# namespace :db do
#   # Shared constants
#   MIGRATION_ORDER = [
#     'admin_users',
#     'active_admin_comments',
#     'counties',
#     'parties',
#     'elections',
#     'people',
#     'party_links',
#     'party_memberships',
#     'people_links',
#     'connections',
#     'election_county_data',
#     'candidate_nominations',
#     'election_party_county_results',
#     'election_party_results',
#     'election_party_national_results'
#   ]
#
#   BOOLEAN_COLUMNS = {
#     'active_admin_comments' => [],
#     'admin_users' => [],
#     'candidate_nominations' => ['qualified'],
#     'counties' => [],
#     'elections' => ['active'],
#     'parties' => ['minority'],
#     'party_links' => [],
#     'party_memberships' => [],
#     'people' => [],
#     'people_links' => ['official'],
#     'connections' => [],
#     'election_party_national_results' => ['over_threshold_cd', 'over_threshold_senate'],
#     'election_party_results' => []
#   }
#
#   def self.log(message)
#     puts "[#{Time.current}] #{message}"
#   end
#
#   desc 'Migrate data from SQLite to PostgreSQL'
#   task migrate_sqlite_to_pg: :environment do
#     begin
#       # Connect to SQLite database
#       sqlite = SQLite3::Database.new('storage/development.sqlite3')
#       sqlite.results_as_hash = true
#
#       # Process tables in order
#       MIGRATION_ORDER.each do |table|
#         log "Processing table: #{table}"
#
#         # Get column names
#         columns = sqlite.execute("PRAGMA table_info('#{table}')").map { |col| col['name'] }
#         log "Columns: #{columns.join(', ')}"
#
#         # Get records
#         records = sqlite.execute("SELECT * FROM '#{table}'")
#         log "Found #{records.count} records"
#
#         # Insert records
#         records.each do |record|
#           # Convert values - handle special cases
#           values = columns.map do |col|
#             value = record[col]
#
#             # Convert booleans
#             if BOOLEAN_COLUMNS[table]&.include?(col) && !value.nil?
#               value.to_i == 1
#             # Handle JSON/JSONB columns
#             elsif col == 'funky_data' && value
#               value = value.is_a?(String) ? JSON.parse(value) : value
#               value.to_json
#             # Handle decimal columns
#             elsif ['percentage_cd', 'percentage_senate'].include?(col)
#               value.to_f
#             else
#               value
#             end
#           end
#
#           # Build insert SQL
#           insert_sql = <<-SQL
#             INSERT INTO #{table} (#{columns.join(', ')})
#             VALUES (#{columns.map { '?' }.join(', ')})
#           SQL
#
#           begin
#             ActiveRecord::Base.connection.execute(
#               ActiveRecord::Base.send(:sanitize_sql_array, [insert_sql, *values])
#             )
#           rescue => e
#             log "Error inserting into #{table}: #{e.message}"
#             log "Record: #{record.inspect}"
#             log "Converted values: #{values.inspect}"
#
#             if e.message.include?("violates foreign key constraint")
#               ref_table = e.message.match(/table "([^"]+)"/)[1]
#               ref_id = e.message.match(/Key \((\w+)\)=\((\d+)\)/)[2]
#               log "Missing reference in #{ref_table} with ID #{ref_id}"
#             end
#           end
#         end
#
#         # Reset sequence if table has id column
#         if columns.include?('id')
#           ActiveRecord::Base.connection.execute(<<-SQL)
#             SELECT setval('#{table}_id_seq', COALESCE((SELECT MAX(id) FROM #{table}), 1), true);
#           SQL
#         end
#
#         log "Completed table: #{table}"
#       end
#
#       log "Migration completed successfully!"
#     rescue => e
#       log "Error during migration: #{e.message}"
#       log e.backtrace.join("\n")
#     ensure
#       sqlite&.close
#     end
#   end
#
#   # Helper task to check data after migration
#   desc 'Verify migration data'
#   task verify_migration: :environment do
#     MIGRATION_ORDER.each do |table|
#       count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{table}").first['count']
#       log "#{table}: #{count} records"
#     end
#   end
#
#   private
#
#   def log(message)
#     self.class.log(message)
#   end
# end