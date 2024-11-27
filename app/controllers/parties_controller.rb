class PartiesController < InheritedResources::Base
  private

    def party_params
      params.require(:party).permit(:name, :color, :logo_url)
    end
end
