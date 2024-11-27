json.extract! candidate_nomination, :id, :county_id, :party_id, :name, :kind, :position, :created_at, :updated_at
json.url candidate_nomination_url(candidate_nomination, format: :json)
