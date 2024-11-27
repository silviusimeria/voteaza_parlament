class CountiesController < InheritedResources::Base
    def panel
      @county = County.find_by!(code: params[:id])
      render partial: "county_panel", locals: { county: @county }
    end

  private

    def county_params
      params.require(:county).permit(:name, :code, :geojson_id)
    end
end
