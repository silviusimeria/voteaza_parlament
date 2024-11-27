json.extract! party_link, :id, :party_id, :url, :kind, :created_at, :updated_at
json.url party_link_url(party_link, format: :json)
