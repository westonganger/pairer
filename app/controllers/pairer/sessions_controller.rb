require_dependency "pairer/application_controller"

module Pairer
  class SessionsController < ApplicationController

    def sign_in
      if request.method == "GET"
        if signed_in?
          redirect_to boards_path
        end

      elsif request.method == "POST"
        if Pairer.config.allowed_org_ids.include?(params[:org_id]&.downcase)
          session[:pairer_current_org_id] = params[:org_id].downcase
          redirect_to boards_path
        end
      end
    end

    def sign_out
      if !signed_in?
        redirect_to action: :sign_in
      else
        session.delete(:pairer_current_org_id)
        session.delete(:pairer_current_board_id)
        flash.notice = "Signed out"
        redirect_to sign_in_path
      end
    end

  end
end
