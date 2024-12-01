module Api
  module V1
    class MapController < BaseController
      def index
        @counties = County.includes(
          candidate_nominations: [ :party, :candidate_links ]
        )

        render json: {
          counties: @counties.map do |county|
            {
              id: county.id,
              name: county.name,
              code: county.code,
              slug: county.slug,
              geojson_id: county.geojson_id,
              candidates: county.candidate_nominations.group_by(&:kind).transform_values do |nominations|
                nominations.map do |nom|
                  {
                    name: nom.name,
                    position: nom.position,
                    party: {
                      name: nom.party.name,
                      color: nom.party.color,
                      logo_url: nom.party.logo_url
                    },
                    links: nom.candidate_links.map { |link|
                      { kind: link.kind, url: link.url }
                    }
                  }
                end
              end
            }
          end
        }
      end
    end
  end
end
