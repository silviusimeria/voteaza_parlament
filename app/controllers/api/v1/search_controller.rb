# app/controllers/api/v1/search_controller.rb
module Api
  module V1
    class SearchController < ApplicationController
      def index
        term = params[:q]&.downcase
        return render json: [] if term.blank? || term.length < 2

        @results = SearchService.new(term).search

        respond_to do |format|
          format.html { render partial: "shared/search_results", locals: { results: @results } }
          format.json { render json: @results }
        end
      end
    end
  end
end
