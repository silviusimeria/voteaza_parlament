require 'csv'
require 'json'
require 'fuzzystringmatch'

namespace :import do
  desc 'Import candidates from CSV files'
  task candidates: :environment do

    def normalize_county_name(name)
      name.strip.downcase.gsub(/[^\w\s]/, '')
    rescue
      name
    end
    def parse_csv(file_path, kind)
      # puts "Parsing CSV file: #{file_path}"

      # Load GeoJSON data from file
      geojson_file = File.read(Rails.root.join('public', 'ro_judete_poligon.geojson'))
      geojson_data = JSON.parse(geojson_file)

      # Extract county data from GeoJSON features
      counties_data = geojson_data['features'].map do |feature|
        {
          name: feature['properties']['name'],
          code: feature['properties']['mnemonic'],
          geojson: feature['geometry']
        }
      end

      # Create a lookup of normalized names to original county data
      county_lookup = counties_data.each_with_object({}) do |county, hash|
        hash[normalize_county_name(county[:name])] = county
      end

      # puts "Found #{counties_data.count} counties"

      CSV.foreach(file_path, headers: true) do |row|
        county_name = row["﻿County"]
        candidate_name = row['Candidate']
        party_name = row['Party']

        normalized_county_name = normalize_county_name(county_name)
        # puts "Processing row: #{row.inspect}"
        # puts "County: #{county_name}, Candidate: #{candidate_name}, Party: #{party_name}"

        next if county_name.nil? || candidate_name.nil? || party_name.nil?

        if county_name.strip == 'Diaspora'
          county = County.find_or_create_by!(name: 'Diaspora', code: 'D') do |c|
            c.geojson_id =  [10,20]
          end
          # puts "Found or created Diaspora county: #{county.name}"
        else
          if county_lookup[normalized_county_name]
            matched_county = county_lookup[normalized_county_name]
            # puts "Exact match found for #{county_name} -> #{matched_county[:name]}"
          else
            # Only use fuzzy matching if exact match fails
            jarow = FuzzyStringMatch::JaroWinkler.create(:native)

            # Debug all potential matches
            scores = counties_data.map do |county|
              score = jarow.getDistance(normalize_county_name(county[:name]), normalized_county_name)
              # puts "#{county_name} <-> #{county[:name]}: score #{score}"
              [county, score]
            end

            best_match = scores.max_by { |_, score| score }

            if best_match[1] > 0.85  # Set a high threshold
              matched_county = best_match[0]
              # puts "Fuzzy match found for #{county_name} -> #{matched_county[:name]} (score: #{best_match[1]})"
            else
              puts "No reliable match found for #{county_name} (best match was #{best_match[0][:name]} with score #{best_match[1]})"
              next  # Skip this record instead of breaking
            end
          end

          if matched_county
            # puts "Matched #{county_name} with #{matched_county[:name]}"
            county = County.find_or_create_by!(name: matched_county[:name]) do |c|
              c.code = matched_county[:code]
              c.geojson_id = matched_county[:geojson].to_json
            end
            # puts "Found or created county: #{county.name}"
          else
            puts "No matching county found for: #{county_name}"
            raise
          end
        end

        party = Party.find_or_create_by!(name: party_name.strip)
        # puts "Found or created party: #{party.inspect}"

        position = CandidateNomination.where(
          county: county,
          party: party,
          kind: kind
        ).count + 1

        candidate_nomination = CandidateNomination.new(
          county: county,
          party: party,
          name: candidate_name.strip,
          kind: kind,
          position: position
        )

        if candidate_nomination.save
          # puts "Created candidate nomination: #{candidate_nomination.name}"
        else
          puts "Failed to create candidate nomination: #{candidate_nomination.errors.full_messages}"
        end
      end
    end

    senate_file_path = Rails.root.join('public', 'senate.csv')
    deputy_file_path = Rails.root.join('public', 'deputy.csv')

    unless File.exist?(senate_file_path)
      puts "Error: File not found at #{senate_file_path}"
      puts "Please place senate.csv in the public directory"
      return
    end

    unless File.exist?(deputy_file_path)
      puts "Error: File not found at #{deputy_file_path}"
      puts "Please place deputy.csv in the public directory"
      return
    end

    parse_csv(senate_file_path, 'senate')
    parse_csv(deputy_file_path, 'deputy')
  end
end