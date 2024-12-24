namespace :import do
  desc "Import additional Funky Citizens data fields"
  task process_funky_data: :environment do
    puts "Processing additional Funky Citizens data fields..."

    json_file = Rails.root.join("public", "date_candidati_funky.json")

    unless File.exist?(json_file)
      puts "Error: File not found at #{json_file}"
      puts "Please ensure date_candidati_funky.json exists in the public directory"
      exit 1
    end

    begin
      data = JSON.parse(File.read(json_file))
      total = data.size
      not_found_names = []

      puts "Found #{total} records to process"

      ActiveRecord::Base.transaction do
        processed = 0
        skipped = 0

        data.each do |row|
          # Find the person by name
          person = Person.find_by(name: row["Nume candidat"])

          if person
            # Process additional fields
            funky_data = {
              county: row["Județ/Circumscripția"],
              party: row["Partid politic"],
              position_type: row["Candidatură de deputat/senator"],
              birth_date: parse_date(row["Data nașterii"]),
              age: row["Vârsta"]&.to_i,
              zodiac: row["Zodia"],
              education_level: row["Nivel de studii"],
              had_prior_position: row["Funcție anterioară primar/ministru/parlamentar/consilier local/consilier județean"] == "DA",
              prior_position: row["Ce funcție?"],
              prior_mandate: row["Mandat anterior"],
              prior_party: row["Partid politic în timpul funcției"],
              last_job: row["Ultimul job"],
              corruption_cases: row["Cazuri de corupție"],
              paid_social_media: row["A plătit publicitate în social media?"] == "DA",
              ad_count: row["Dacă da, câte?"]&.gsub(/[^\d]/, "")&.to_i,
              used_disclaimer: row["A folosit disclaimer?"] == "DA",
              positions: {
                lgbt: row["A avut poziții pe comunitatea LGBT?"] == "DA",
                anticorruption: row["A avut poziții pe anticorupție?"] == "DA",
                climate: row["A avut poziții pe schimbările climatice?"] == "DA",
                development: row["A avut poziții pe dezvoltare regională/locală?"] == "DA",
                inflation: row["A avut poziții pe inflație și costul vieții?"] == "DA",
                eu: row["Pro/anti-UE"] == "DA",
                ukraine: row["A avut poziție pe Ucraina?"] == "DA"
              }
            }

            person.update!(funky_data: funky_data)
            processed += 1

            if (processed % 10).zero?
              print "\rProcessed #{processed}/#{total} records (#{(processed.to_f/total * 100).round(1)}%)"
            end
          else
            not_found_names << {
              name: row["Nume candidat"],
              county: row["Județ/Circumscripția"],
              party: row["Partid politic"]
            }
            skipped += 1
          end
        end

        puts "\nImport Summary:"
        puts "----------------"
        puts "Total records: #{total}"
        puts "Successfully processed: #{processed}"
        puts "Skipped (not found): #{skipped}"

        if not_found_names.any?
          puts "\nCandidates not found in database:"
          puts "--------------------------------"
          not_found_names.each do |entry|
            puts "- #{entry[:name]} (#{entry[:party]} - #{entry[:county]})"
          end

          # Optionally save to a file
          error_log = Rails.root.join("log", "funky_import_errors.log")
          File.open(error_log, "w") do |f|
            f.puts "Import run at: #{Time.current}"
            f.puts "\nCandidates not found in database:"
            not_found_names.each do |entry|
              f.puts "- #{entry[:name]} (#{entry[:party]} - #{entry[:county]})"
            end
          end
          puts "\nDetailed error log saved to: #{error_log}"
        end

        # Print some stats about the successful imports
        if processed > 0
          puts "\nSuccessful Import Statistics:"
          puts "----------------------------"
          puts "Total People with Funky data: #{Person.where.not(funky_data: nil).count}"
          puts "Data by position type:"
          Person.where.not(funky_data: nil).group("funky_data->>'position_type'").count.each do |type, count|
            puts "  #{type}: #{count}"
          end
        end
      end

    rescue JSON::ParserError => e
      puts "Error parsing JSON file: #{e.message}"
      exit 1
    rescue StandardError => e
      puts "Error during processing: #{e.message}"
      puts e.backtrace
      exit 1
    end
  end

  private

  def parse_date(date_string)
    return nil if date_string.blank?
    Date.strptime(date_string, "%m/%d/%y")
  rescue Date::Error
    nil
  end
end
