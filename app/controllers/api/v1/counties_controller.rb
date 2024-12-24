# app/controllers/api/v1/counties_controller.rb
module Api
  module V1
    class CountiesController < BaseController
      def show
        @county = County.find_by!(slug: params[:slug])
        render json: @county
      end
    end
  end
end
