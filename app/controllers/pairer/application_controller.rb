module Pairer
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    helper_method :signed_in?

    if defined?(::ControllerExceptionsConcern)
      ### if defined in top-level application
      include ::ControllerExceptionsConcern
    end

    def robots
      str = <<~STR
        User-agent: *
        Disallow: /
      STR

      render plain: str, layout: false, content_type: 'text/plain'
    end

    def render_404
      if request.format.html?
        render "pairer/exceptions/show", status: 404
      else
        render plain: "404 Not Found", status: 404
      end
    end

    def signed_in?
      if session[:pairer_current_org_id].present?
        Pairer.allowed_org_ids.collect(&:downcase).include?(session[:pairer_current_org_id].downcase)
      end
    end

    private 

    rescue_from ActiveRecord::RecordNotFound do |e|
      raise ActionController::RoutingError.new('Not Found')
    end

  end
end
