source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Declare your gem's dependencies in coders_log.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
# gem 'byebug', group: [:development, :test]

def get_env(name)
  (ENV[name] && !ENV[name].empty?) ? ENV[name] : nil
end

gem "rails", get_env("RAILS_VERSION")


if get_env("RAILS_VERSION").to_f >= 7.2
  gem "activerecord-enhancedsqlite3-adapter"
  gem "sqlite3", "~> 2.0"
else
  gem "sqlite3", "~> 1.7"
end

group :development do
  gem "puma"
end
