require "open-uri"

namespace :vote_results do
  desc "Inspect vote results JSON structure"
  task inspect_structure: :environment do
    url = "https://prezenta.roaep.ro/parlamentare01122024/data/json/sicpv/pv/pv_aggregated.json"
    results = JSON.parse(URI.parse(url).open.read)

    def print_structure(obj, indent = 0)
      case obj
      when Hash
        obj.each do |k, v|
          puts "  " * indent + "#{k}: #{v.class}"
          print_structure(v, indent + 1) if v.is_a?(Hash) || v.is_a?(Array)
        end
      when Array
        return if obj.empty?
        puts "  " * indent + "Array contains: #{obj.first.class}"
        print_structure(obj.first, indent + 1) if obj.first.is_a?(Hash) || obj.first.is_a?(Array)
      end
    end

    print_structure(results)
  end
end
