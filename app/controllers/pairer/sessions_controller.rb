require_dependency "pairer/application_controller"

module Pairer
  class SessionsController < ApplicationController

    def sign_in
      if request.method == "GET"
        if signed_in?
          redirect_to boards_path
        end

      elsif request.method == "POST"
        if Pairer.allowed_org_names.include?(params[:org_name]&.downcase)
          session[:current_org_name] = params[:org_name].downcase
          redirect_to boards_path
        end
      end
    end

    def sign_out
      if !signed_in?
        redirect_to action: :sign_in
      else
        session.delete(:current_org_name)
        session.delete(:current_board_id)
        flash.notice = "Signed out"
        redirect_to sign_in_path
      end
    end

  end
end
