class PeopleController < ApplicationController
  def show
    @person = Person.find_by!(slug: params[:slug])

    @nominations = CandidateNomination.includes(:party, :candidate_links, :county)
                                     .where(person: @person)
  end
end