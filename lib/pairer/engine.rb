require 'slim'
require 'hashids'

module Pairer
  class Engine < ::Rails::Engine
    isolate_namespace Pairer

    initializer "pairer.append_migrations" do |app|
      ### Automatically load all migrations into main rails app

      if !app.root.to_s.match?(root.to_s)
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    initializer "pairer.load_static_assets" do |app|
      ### Expose static assets
      app.middleware.use ::ActionDispatch::Static, "#{root}/public"
    end

    ### Were not using sprockets were just storing everything in public
    ### Sprockets Config below
    # initializer "rails_i18n_manager.assets.precompile" do |app|
    #   app.config.assets.precompile << "rails_i18n_manager_manifest.js" ### manifest file required
    #   app.config.assets.precompile << "rails_i18n_manager/favicon.ico"

    #   ### Automatically precompile assets in specified folders
    #   ["app/assets/images/"].each do |folder|
    #     dir = app.root.join(folder)

    #     if Dir.exist?(dir)
    #       Dir.glob(File.join(dir, "**/*")).each do |f|
    #         asset_name = f.to_s
    #           .split(folder).last # Remove fullpath
    #           .sub(/^\/*/, '') ### Remove leading '/'

    #         app.config.assets.precompile << asset_name
    #       end
    #     end
    #   end
    # end

  end
end
