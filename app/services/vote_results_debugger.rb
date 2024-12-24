class VoteResultsDebugger
  def initialize(election, results_json)
    @election = election
    @results = JSON.parse(results_json)
    @county_mappings = initialize_county_mappings
  end

  def debug_structure
    puts "\nData Structure:"
    puts @results.keys.inspect
    if @results["scopes"]
      cnty = @results["scopes"]["CNTY"]
      puts "\nChambers in CNTY:"
      puts cnty.keys.inspect if cnty

      if cnty && cnty["CD"]
        cd_sample = cnty["CD"].first
        puts "\nFirst CD county data:"
        puts cd_sample.inspect if cd_sample
      end
    end
  end

  def debug_sample_data
    if @results["scopes"] && @results["scopes"]["CNTY"] && @results["scopes"]["CNTY"]["CD"]
      county_data = @results["scopes"]["CNTY"]["CD"].first
      puts "\nSample County Data:"
      pp county_data

      if county_data[1] && county_data[1]["candidates"]
        puts "\nSample Candidate:"
        pp county_data[1]["candidates"].first
      end
    end
  end

  def debug_county_mappings
    puts "\nCounty Mappings:"
    @county_mappings.sort_by { |k, _| k }.each do |aep_id, county_id|
      county = County.find(county_id)
      aep_data = @results["scopes"]["CNTY"]["CD"][aep_id]
      if aep_data
        aep_name = aep_data["info"]["county"] rescue "Unknown"
        puts "#{aep_id} -> #{county.code} (#{county.name})"
        puts "  AEP: #{aep_name}"
      end
    end

    puts "\nUnmapped Counties in AEP data:"
    @results["scopes"]["CNTY"]["CD"].each do |id, data|
      unless @county_mappings[id]
        county_name = data["info"]["county"] rescue "Unknown"
        puts "#{id}: #{county_name}"
      end
    end
  end

  private

  def initialize_county_mappings
    mappings = {}
    County.find_each do |county|
      case county.code
      when "D"
        mappings["43"] = county.id # Strainatate
      when "B"
        # Map all Bucharest sectors to București
        ("44".."49").each { |sector_id| mappings[sector_id] = county.id }
        mappings["42"] = county.id
      else
        @results["scopes"]["CNTY"]["CD"].each do |id, data|
          county_name = data["info"]["county"] rescue next
          next unless county_name

          if normalize_string(county.name) == normalize_string(county_name)
            mappings[id] = county.id
          end
        end
      end
    end
    mappings
  end

  def normalize_string(str)
    return "" unless str
    str.unicode_normalize(:nfkd)
       .encode("ASCII", replace: "")
       .upcase
       .gsub(/[^A-Z\-]/, "")
  end
end
