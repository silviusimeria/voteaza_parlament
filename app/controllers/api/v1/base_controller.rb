# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ActionController::API
      include Pundit::Authorization

      rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
      rescue_from ActiveRecord::RecordNotFound, with: :not_found

      private

      def user_not_authorized
        render json: { error: "Unauthorized" }, status: :unauthorized
      end

      def not_found
        render json: { error: "Not found" }, status: :not_found
      end
    end
  end
end
