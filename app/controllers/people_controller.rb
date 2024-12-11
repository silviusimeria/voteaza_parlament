class PeopleController < ApplicationController
  def show
    @person = Person.where(slug: params[:slug]).last # until we fix DB duplicates :)
    @nominations = @person.candidate_nominations.includes(:county, :party)
  end
end