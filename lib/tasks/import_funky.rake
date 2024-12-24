namespace :import do
  desc "Import candidate data from Funky Citizens JSON file"
  task funky: :environment do
    puts "Starting Funky Citizens data import..."

    json_file = Rails.root.join("public", "date_candidati_funky.json")

    unless File.exist?(json_file)
      puts "Error: File not found at #{json_file}"
      puts "Please ensure date_candidati_funky.json exists in the public directory"
      exit 1
    end

    begin
      data = JSON.parse(File.read(json_file))
      total = data.size

      puts "Found #{total} records to process"

      ActiveRecord::Base.transaction do
        processed = 0

        data.each do |row|
          FunkyDataImportService.import([ row ])
          processed += 1

          if (processed % 10).zero? # Show progress every 10 records
            print "\rProcessed #{processed}/#{total} records (#{(processed.to_f/total * 100).round(1)}%)"
          end
        end

        puts "\nCompleted importing #{processed} records"
      end

      # Print some stats
      puts "\nImport Statistics:"
      puts "Total People: #{Person.count}"
      puts "Total Links: #{PeopleLink.count}"
      puts "Links by type:"
      PeopleLink.group(:kind).count.each do |kind, count|
        puts "  #{kind}: #{count}"
      end

    rescue JSON::ParserError => e
      puts "Error parsing JSON file: #{e.message}"
      exit 1
    rescue StandardError => e
      puts "Error during import: #{e.message}"
      puts e.backtrace
      exit 1
    end
  end

  desc "Clear all funky citizens imported data"
  task clear_funky: :environment do
    if Rails.env.production?
      puts "Cannot run in production without confirmation!"
      puts "Run with CONFIRM=yes to proceed"
      exit 1 unless ENV["CONFIRM"] == "yes"
    end

    ActiveRecord::Base.transaction do
      puts "Clearing all people links..."
      PeopleLink.delete_all

      puts "Clearing funky_data from people..."
      Person.update_all(funky_data: nil)

      puts "Data cleared successfully!"
    end
  end
end
