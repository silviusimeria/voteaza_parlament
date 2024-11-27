class CandidateLinksController < InheritedResources::Base
  private

    def candidate_link_params
      params.require(:candidate_link).permit(:candidate_nomination_id, :url, :kind)
    end
end
