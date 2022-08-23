require_dependency "pairer/application_controller"

module Pairer
  class MainController < ApplicationController
    before_action except: [:sign_in] do
      if !signed_in?
        redirect_to action: :sign_in
      end
    end

    before_action :get_board, except: [:index, :new, :create, :sign_in, :sign_out]

    def index
      if params[:password].present?
        @board = Pairer::Board.find_by(org_name: session[:current_org_name], password: params[:password])
        if @board
          session[:current_board_id] = @board.to_param
          redirect_to action: :show, id: session[:current_board_id]
        else
          flash.now.alert = "Board not found."
          render
        end
      end
    end

    def sign_in
      if request.method == "GET"
        if signed_in?
          redirect_to(action: :index)
        end

      elsif request.method == "POST"
        if Pairer.allowed_org_names.include?(params[:org_name]&.downcase)
          session[:current_org_name] = params[:org_name].downcase
          redirect_to(action: :index)
        end
      end
    end

    def sign_out
      session.delete(:current_org_name)
      session.delete(:current_board_id)
      flash.notice = "Signed out"
      redirect_to(action: :sign_in)
    end

    def create
      @board = Pairer::Board.new(password: params[:password], org_name: session[:current_org_name])

      if @board.save
        session[:current_board_id] = @board.to_param
        flash.notice = "Board created."
        redirect_to(action: :show, id: @board.to_param)
      else
        other_board = Pairer::Board.find_by(org_name: session[:current_org_name], password: params[:password])

        if other_board
          session[:current_board_id] = other_board.to_param
          flash.notice = "Existing board found."
          redirect_to(action: :show, id: other_board.to_param)
        else
          flash.alert = "Board not saved. Please choose a different password."
          redirect_to(action: :index)
        end
      end
    end

    def show
    end

    def update
      if params[:add_role_name]
        params[:board] = {}
        params[:board][:roles] = @board.roles_array + [params[:add_role_name]]
      elsif params[:remove_role_name]
        params[:board] = {}
        params[:board][:roles] = @board.roles_array - [params[:remove_role_name]]
        Rails.logger.debug("*"*1000)
        Rails.logger.debug params[:board][:roles]
      end

      if params[:clear_board]
        @board.groups.destroy_all
        @board.update!(current_iteration_number: 0)
        saved = true
      else
        saved = @board.update(params.require(:board).permit(:name, :password, :group_size, :num_iterations_to_track, roles: []))
      end
      
      if saved
        if params.dig(:board, :password)
          flash.notice = "Password updated."
        elsif
          flash.notice = "Board updated."
        end
      else
        flash.alert = "Board not saved."
      end

      redirect_to(action: :show)
    end

    def destroy
      @board.destroy!
      flash.notice = "Board deleted."
      redirect_to(action: :index)
    end

    def shuffle
      @board.shuffle!
      redirect_to(action: :show)
    end

    def create_person
      @board.people.create(name: params[:name])
      redirect_to(action: :show)
    end

    def lock_person
      @board.people.find_by!(public_id: params.require(:person_id)).toggle!(:locked)
      redirect_to(action: :show)
    end

    def delete_person
      @board.people.find_by!(public_id: params.require(:person_id)).destroy!
      redirect_to(action: :show)
    end

    def create_group
      @board.groups.create!(board_iteration_number: @board.current_iteration_number)
      redirect_to(action: :show)
    end

    def lock_group
      @board.groups.find_by!(public_id: params.require(:group_id)).toggle!(:locked)
      redirect_to(action: :show)
    end

    def delete_group
      @board.groups.find_by!(public_id: params.require(:group_id)).destroy!
      redirect_to(action: :show)
    end

    def update_group
      @group = @board.groups.find_by!(public_id: params.require(:group_id))

      attrs = {
        person_ids: (params[:person_ids] if params[:person_ids].present?),
        roles: (params[:roles] if params[:roles].present?),
      }.compact
      
      @group.update!(attrs)

      if request.format.js?
        render inline: "", layout: "pairer/application"
      else
        redirect_to(action: :show)
      end
    end

    private

    def get_board
      if session[:current_board_id].blank?
        redirect_to(action: :index)
      end

      @board = Pairer::Board.find_by!(org_name: session[:current_org_name], public_id: params[:id])
    end

  end
end
