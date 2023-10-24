require 'slim'
require 'sassc-rails'
require 'bootstrap-sass'
require 'bootswatch-rails'
require 'hashids'

module Pairer
  class Engine < ::Rails::Engine
    isolate_namespace Pairer

    initializer "pairer.assets.precompile" do |app|
      app.config.assets.precompile << "pairer_manifest.js" ### manifest file required
      app.config.assets.precompile << "pairer/favicon.ico"

      ### Automatically precompile assets in specified folders
      ["app/assets/images/"].each do |folder|
        dir = app.root.join(folder)

        if Dir.exist?(dir)
          Dir.glob(File.join(dir, "**/*")).each do |f|
            asset_name = f.to_s
              .split(folder).last # Remove fullpath
              .sub(/^\/*/, '') ### Remove leading '/'

            app.config.assets.precompile << asset_name
          end
        end
      end
    end

    initializer "pairer.load_static_assets" do |app|
      ### Expose static assets
      app.middleware.use ::ActionDispatch::Static, "#{root}/public"
    end

  end
end
