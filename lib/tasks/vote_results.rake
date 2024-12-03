require 'open-uri'

namespace :vote_results do
  desc "Fetch and process vote results from AEP for current election"
  task process: :environment do
    election = Election.active.first
    unless election
      puts "No active election found"
      exit
    end

    url = "https://prezenta.roaep.ro/parlamentare01122024/data/json/sicpv/pv/pv_aggregated.json"
    results_json = URI.parse(url).open.read

    # puts "Received JSON structure:"
    # puts JSON.parse(results_json).inspect

    processor = VoteResultsProcessor.new(election, results_json)
    processor.process
  end
end