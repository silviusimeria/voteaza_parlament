json.extract! candidate_link, :id, :candidate_nomination_id, :url, :kind, :created_at, :updated_at
json.url candidate_link_url(candidate_link, format: :json)
