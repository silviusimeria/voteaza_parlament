class CountiesController < InheritedResources::Base
  def show
    Rails.logger.debug "PARAMS: #{params.inspect}"

    @county = County.find_by!(slug: params[:county_slug])
    @party = Party.find_by(slug: params[:party_slug]) if params[:party_slug]
    @candidate = CandidateNomination.find_by(slug: params[:candidate_slug]) if params[:candidate_slug]

    Rails.logger.debug "COUNTIES#SHOW: county: #{@county.slug}, party: #{@party&.slug}, candidate: #{@candidate&.slug}"

    respond_to do |format|
      format.html do
        Rails.logger.debug "COUNTIES#SHOW HTML FORMAT"
      end
      format.turbo_stream do
        Rails.logger.debug "COUNTIES#SHOW TURBO_STREAM FORMAT"
        streams = []
        streams << turbo_stream.update("county-info", partial: "county_panel")
        streams << turbo_stream.update("popup-container", partial: "candidate_popup") if @candidate

        render turbo_stream: streams
      end
    end
  end
end