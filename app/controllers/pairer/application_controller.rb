module Pairer
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    helper_method :signed_in?

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
        Pairer.config.allowed_org_ids.collect(&:downcase).include?(session[:pairer_current_org_id].downcase)
      end
    end

  end
end
