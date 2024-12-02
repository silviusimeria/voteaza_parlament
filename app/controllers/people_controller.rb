class PeopleController < ApplicationController
  def show
    @person = Person.find_by!(slug: params[:slug])
    @nominations = @person.candidate_nominations.includes(:county, :party)
  end
end