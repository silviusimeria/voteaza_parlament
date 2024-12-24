# require 'sqlite3'
# require 'pg'
# require 'yaml'
#
# namespace :db do
#   desc 'Migrate SQLite data to PostgreSQL'
#   task migrate_to_pg: :environment do
#     # SQLite connection
#     sqlite_db = SQLite3::Database.new('storage/development.sqlite3')
#     sqlite_db.results_as_hash = true
#
#     # Get all tables
#     tables = sqlite_db.execute(<<-SQL)
#       SELECT name FROM sqlite_master
#       WHERE type='table'
#       AND name NOT LIKE 'sqlite_%'
#       AND name NOT LIKE 'schema_migrations'
#       AND name NOT LIKE 'ar_internal_metadata';
#     SQL
#
#     # For each table
#     tables.each do |table|
#       table_name = table['name']
#       puts "Migrating #{table_name}..."
#
#       # Get the records from SQLite
#       records = sqlite_db.execute("SELECT * FROM #{table_name}")
#
#       next if records.empty?
#
#       # Get columns for this table
#       columns = sqlite_db.execute("PRAGMA table_info(#{table_name})").map { |col| col['name'] }
#
#       records.each do |record|
#         # Convert values and handle special cases
#         column_value_pairs = columns.map do |col|
#           value = record[col]
#
#           # Convert specific value types
#           converted_value = case value
#           when 0, 1
#             if ['boolean', 'bool'].include?(column_types[col.to_s])
#               value == 1
#             else
#               value
#             end
#           when nil
#             'NULL'
#           else
#             value
#           end
#
#           [col, converted_value]
#         end.to_h
#
#         # Build the insert SQL with proper value placeholders
#         columns_string = column_value_pairs.keys.join(', ')
#         values_string = column_value_pairs.values.map { |v| v == 'NULL' ? 'NULL' : '?' }.join(', ')
#         values = column_value_pairs.values.reject { |v| v == 'NULL' }
#
#         sql = "INSERT INTO #{table_name} (#{columns_string}) VALUES (#{values_string})"
#
#         begin
#           ActiveRecord::Base.connection.execute(
#             sanitize_sql([sql] + values)
#           )
#         rescue => e
#           puts "Error inserting record in #{table_name}: #{e.message}"
#           puts "SQL: #{sql}"
#           puts "Values: #{values.inspect}"
#           # Continue with next record
#         end
#       end
#
#       # Reset sequence
#       if columns.include?('id')
#         ActiveRecord::Base.connection.execute(<<-SQL)
#           SELECT setval(
#             '#{table_name}_id_seq',
#             COALESCE((SELECT MAX(id) FROM #{table_name}), 0) + 1,
#             false
#           );
#         SQL
#       end
#
#       puts "Completed migrating #{table_name}"
#     end
#
#     sqlite_db.close
#     puts "Migration completed!"
#   end
#
#   private
#
#   def sanitize_sql(sql_array)
#     ActiveRecord::Base.send(:sanitize_sql_array, sql_array)
#   end
#
#   def column_types
#     @column_types ||= {}
#   end
# end