class CandidateNominationsController < InheritedResources::Base
  private

    def candidate_nomination_params
      params.require(:candidate_nomination).permit(:county_id, :party_id, :name, :kind, :position)
    end
end
