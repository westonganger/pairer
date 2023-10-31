# Pairer

<a href="https://badge.fury.io/rb/pairer" target="_blank"><img height="21" style='border:0px;height:21px;' border='0' src="https://badge.fury.io/rb/pairer.svg" alt="Gem Version"></a>
<a href='https://github.com/westonganger/pairer/actions' target='_blank'><img src="https://github.com/westonganger/pairer/actions/workflows/test.yml/badge.svg?branch=master" style="max-width:100%;" height='21' style='border:0px;height:21px;' border='0' alt="CI Status"></a>
<a href='https://rubygems.org/gems/pairer' target='_blank'><img height='21' style='border:0px;height:21px;' src='https://img.shields.io/gem/dt/pairer?color=brightgreen&label=Rubygems%20Downloads' border='0' alt='RubyGems Downloads' /></a>

Pairer is a Rails app/engine to help you to easily generate and rotate pairs within a larger group. For example its great for pair programming teams where you want to work with someone new everyday.

Each organization has many boards. Within each board you can create people and roles. The tool will allow for both automated and manual assignments of these resources to working groups within the board.

![Screenshot](/screenshot.png)

## Setup

Developed as a Rails engine. So you can add to any existing app or create a brand new app with the functionality.

First add the gem to your Gemfile

```ruby
### Gemfile
gem 'pairer'
```

Then install and run the database migrations

```sh
bundle install
bundle exec rake pairer:install:migrations
bundle exec rake db:migrate
```

#### Option A: Mount to a path

```ruby
### config/routes.rb

### As sub-path
mount Pairer::Engine, at: "/pairer", as: "pairer"

### OR as root-path
mount Pairer::Engine, at: "/", as: "pairer"
```

#### Option B: Mount as a subdomain

```ruby
### config/routes.rb

pairer_subdomain = "pairer"

mount Pairer::Engine,
  at: "/", as: "pairer",
  constraints: Proc.new{|request| request.subdomain == pairer_subdomain }

not_engine = Proc.new{|request| request.subdomain != pairer_subdomain }

constraints not_engine do
  # your app routes here...
end
```

### Configuration Options

```ruby
### config/initializers/pairer.rb

Pairer.config do |config|
  config.hash_id_salt = "Fy@%p0L^$Je6Ybc9uAjNU&T@" ### Dont lose this, this is used to generate public_ids for your records using hash_ids gem

  config.allowed_org_ids = ["example-org", "other-example-org"]
  ### OR something more secure, for example
  config.allowed_org_ids = ["pXtHe7YUW0@Wo$H3V*s6l4N5"]

  config.max_iterations_to_track = 100 # Defaults to 100
end
```

## How Authentication Works

Authentication models is as follows:

1. Your main app defines a list of `Pairer.config.allowed_org_ids`. When an unauthenticated user visits the site they are taken to the sign-in page. On this page they are required to enter an "Organization ID" if they enter one of the `Pairer.config.allowed_org_ids` then they are signed-in to pairer and all boards will be scoped accordingly.

2. After the user is signed-in via #1 above, then the user can either A. access existing board by entering the boards password, or B. create a new board by defining a board password.

3. Since the authentication model is loose by design, it is strongly recommended that you add the gem `rack-attack` to your main application and configure it to prevent brute force attacks from unauthorized attackers

```ruby
### Gemfile
gem "rack-attack"
```

```ruby
### config/initializers/pairer.rb

Rack::Attack.throttle('limit unauthorized non-get requests', limit: 5, period: 1.minute) do |req|
  if req.get?
    subdomain = req.host.split('.').first
    site_is_pairer = subdomain&.casecmp?("pairer") ### Replace this with whatever logic is applicable to your app

    if site_is_pairer && !Pairer.config.allowed_org_ids.include?(req.session[:pairer_current_org_id])
      ### Not signed-in to Pairer
      req.ip
    end
  end
end
```

## Configuring Exception Handling

If you want to add exception handling/notifications you can easily just add the behaviour directly to pairers application controller and do your custom exception handling logic. For example:

```ruby
Pairer::ApplicationController.class_eval do
  rescue_from Exception do |exception|
    ExceptionNotifier.notify_exception(exception)
    render plain: "System error", status: 500
  end
end
```

## Development

Run migrations using: `rails db:migrate`

Run server using: `bin/dev` or `cd test/dummy/; rails s`

## Testing

```
bundle exec rspec
```

We can locally test different versions of Rails using `ENV['RAILS_VERSION']`

```
export RAILS_VERSION=7.0
bundle install
bundle exec rspec
```

# Credits

Created & Maintained by [Weston Ganger](https://westonganger.com) - [@westonganger](https://github.com/westonganger)
