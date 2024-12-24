# namespace :db do
#   desc 'Get schema information'
#   task schema_info: :environment do
#     # Load all models
#     Rails.application.eager_load!
#
#     # Store column types for all tables
#     File.open('tmp/column_types.yml', 'w') do |file|
#       column_types = ActiveRecord::Base.descendants.each_with_object({}) do |model, types|
#         next if model.abstract_class?
#
#         types[model.table_name] = model.columns_hash.transform_values(&:type)
#       end
#
#       file.write(column_types.to_yaml)
#     end
#   end
# end