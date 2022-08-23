$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "pairer/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "pairer"
  spec.version     = Pairer::VERSION
  spec.authors     = ["Weston Ganger"]
  spec.email       = ["weston@westonganger.com"]
  spec.homepage    = "https://github.com/westonganger/pairer"
  spec.summary     = "Rails app/engine to Easily rotate and keep track of working pairs"
  spec.description = spec.summary
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib,public}/**/*", "LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 6.0"
  spec.add_dependency "slim"
  spec.add_dependency "sassc-rails"
  spec.add_dependency "bootstrap-sass", "~>3.0"
  spec.add_dependency "bootswatch-rails", "~>3.0"
  spec.add_dependency "hashids"

  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "factory_bot"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "pry-rails"
  spec.add_development_dependency "rails-controller-testing"
end
