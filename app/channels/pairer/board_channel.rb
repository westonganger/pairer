module Pairer
  class BoardChannel < ApplicationCable::Channel
    def subscribed
      stream_from "board_#{params[:id]}"
    end
  end
end
