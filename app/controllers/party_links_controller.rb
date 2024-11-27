class PartyLinksController < InheritedResources::Base
  private

    def party_link_params
      params.require(:party_link).permit(:party_id, :url, :kind)
    end
end
