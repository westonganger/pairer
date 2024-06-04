require_dependency "pairer/application_controller"

module Pairer
  class BoardsController < ApplicationController
    before_action do
      if !signed_in?
        redirect_to sign_in_path
      end
    end

    before_action :get_board, except: [:index, :new, :create]

    helper_method :people_by_id

    def index
      if params[:password].present?
        @board = Pairer::Board.find_by(org_id: session[:pairer_current_org_id], password: params[:password])

        if @board
          session[:pairer_current_board_id] = @board.to_param
          redirect_to action: :show, id: session[:pairer_current_board_id]
        else
          flash.now.alert = "Board not found."

          render
        end
      end
    end

    def create
      @board = Pairer::Board.new(password: params[:password], org_id: session[:pairer_current_org_id])

      if @board.save
        session[:pairer_current_board_id] = @board.to_param
        flash.notice = "Board created."
        redirect_to(action: :show, id: @board.to_param)
      else
        other_board = Pairer::Board.find_by(org_id: session[:pairer_current_org_id], password: params[:password])

        if other_board
          session[:pairer_current_board_id] = other_board.to_param
          flash.notice = "Existing board found."
          redirect_to(action: :show, id: other_board.to_param)
        else
          flash.alert = "Board not saved. Please choose a different password."
          redirect_to(action: :index)
        end
      end
    end

    def show
      session_key = :pairer_board_access_list

      access_list = session[session_key] || {}

      access_list[@board.public_id] = Time.now.to_s

      session[session_key] = access_list
    end

    def update
      if params[:add_role_name]
        params[:board] = {}
        params[:board][:roles] = @board.roles_array + [params[:add_role_name]]
      elsif params[:remove_role_name]
        params[:board] = {}
        params[:board][:roles] = @board.roles_array - [params[:remove_role_name]]
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
        else
          flash.notice = "Board updated."
        end

        broadcast_changes
      else
        if @board.errors[:num_iterations_to_track].present?
          flash.alert = "Number of Iterations to Track #{@board.errors[:num_iterations_to_track].first}"
        else
          flash.alert = "Board not saved."
        end
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
      broadcast_changes
      redirect_to(action: :show)
    end

    def create_person
      @person = @board.people.create(name: params[:name])

      if @person.persisted?
        broadcast_changes
      end

      if request.format.js?
        render_js_page_replace
      else
        redirect_to(action: :show)
      end
    end

    def lock_person
      @person = @board.people.find_by!(public_id: params.require(:person_id))

      @person.toggle!(:locked)
      broadcast_changes

      if request.format.js?
        render_js_page_replace
      else
        redirect_to(action: :show)
      end
    end

    def delete_person
      @person = @board.people.find_by!(public_id: params.require(:person_id))

      @person.destroy!
      broadcast_changes

      redirect_to(action: :show)
    end

    def create_group
      @group = @board.groups.create!(board_iteration_number: @board.current_iteration_number)
      broadcast_changes

      if request.format.js?
        render_js_page_replace
      else
        redirect_to(action: :show)
      end
    end

    def lock_group
      @group = @board.current_groups.find_by!(public_id: params.require(:group_id))

      @group.toggle!(:locked)
      broadcast_changes

      if request.format.js?
        render_js_page_replace
      else
        redirect_to(action: :show)
      end
    end

    def delete_group
      @group = @board.current_groups.find_by!(public_id: params.require(:group_id))

      @group.destroy!
      broadcast_changes

      if request.format.js?
        render_js_page_replace
      else
        redirect_to(action: :show)
      end
    end

    def update_group
      @group = @board.current_groups.find_by!(public_id: params.require(:group_id))

      person_ids_was = @group.person_ids_array
      roles_was = @group.roles_array

      attrs = {
        person_ids: (params[:person_ids] if params[:person_ids].present?),
        roles: (params[:roles] if params[:roles].present?),
      }.compact

      @group.assign_attributes(attrs)

      new_person_ids = @group.person_ids_array - person_ids_was
      new_roles = @group.roles_array - roles_was

      if @group.changed?
        changed = true

        if params[:removal] == "true"
          @group.save!
        else
          ActiveRecord::Base.transaction do
            @group.save!

            if new_person_ids.any?
              @board.current_groups.detect do |g|
                next if g.id == @group.id

                if g.person_ids_array.intersection(new_person_ids).any?
                  g.person_ids = g.person_ids_array - @group.person_ids_array
                  g.save!
                  true
                end
              end
            end

            if new_roles.any?
              @board.current_groups.detect do |g|
                next if g.id == @group.id

                if g.roles_array.intersection(new_roles).any?
                  g.roles = g.roles_array - @group.roles_array
                  g.save!
                  true
                end
              end
            end
          end
        end

        broadcast_changes
      end

      if request.format.js?
        render_js_page_replace
      else
        redirect_to(action: :show)
      end
    end

    private

    def get_board
      if session[:pairer_current_board_id].blank?
        redirect_to(action: :index)
      end

      @board = Pairer::Board.find_by!(org_id: session[:pairer_current_org_id], public_id: params[:id])
    end

    def people_by_id
      @people_by_id ||= @board.people.map{|x| [x.to_param, x] }.to_h
    end

    def broadcast_changes
      ActionCable.server.broadcast(
        "board_#{@board.public_id}",
        {
          action: "reload",
          identifier: session[:pairer_user_id],
        }
      )
    end

    include ActionView::Helpers::JavaScriptHelper
    def render_js_page_replace
      @board.reload

      js_page_content = escape_javascript(render_to_string "pairer/boards/show", layout: false)

      javascript = <<~STR
        $("#page-content").html("#{js_page_content}");
      STR

      render(js: javascript)
    end

  end
end
