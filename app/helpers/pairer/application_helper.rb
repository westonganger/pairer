module Pairer
  module ApplicationHelper

    ASSET_VERSION = `git show -s --format=%ci`.parameterize.freeze
    def custom_asset_path(path)
      "#{path}?v=#{Rails.env.development? ? Time.now.to_i : ASSET_VERSION}"
    end

  end
end
