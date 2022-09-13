# Pairer Engine

<a href='https://github.com/westonganger/pairer/actions' target='_blank'><img src="https://github.com/westonganger/pairer/workflows/Tests/badge.svg" style="max-width:100%;" height='21' style='border:0px;height:21px;' border='0' alt="CI Status"></a>

This is a Rails app/engine to help you to easily rotate and keep track of working pairs. For example its great for pair-programming teams.

Each organization has many boards. Within each Board you can create people and roles. The tool will allow for automated and manually assignments of people and roles to working groups within the board.

![Screenshot](/screenshot.png)

## Setup

Developed as a Rails engine. So you can add to any existing app or create a brand new app with the functionality.

```ruby
### Gemfile
gem 'pairer', git: 'https://github.com/westonganger/pairer'
```

```ruby
### config/initializers/pairer.rb

#Pairer.max_iterations_to_track = 100 # Default 100

Pairer.allowed_org_ids = ["example-org", "other-example-org"]

### OR something more secure, for example
Pairer.allowed_org_ids = ["pXtHe7YUW0@Wo$H3V*s6l4N5"]
```

### Option A: Configure as a sub-path

```ruby
### config/routes.rb

### As sub-path
mount Pairer::Engine, at: "/pairer", as: "pairer"

### OR as root-path
mount Pairer::Engine, at: "/", as: "pairer"
```

### Option B: Configure as a subdomain

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

## How Authentication Works

Authentication models is as follows:

1. Your main app defines a list of `Pairer.allowed_org_ids`. When an unauthenticated user visits the site they are taken to the sign-in page. On this page they are required to enter an "Organization ID" if they enter one of the `Pairer.allowed_org_ids` then they are signed-in to pairer and all boards will be scoped accordingly.

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

    if !Pairer.allowed_org_ids.include?(req.session[:pairer_current_org_id])
      ### Not signed-in to Pairer
      req.ip
    end
  end
end
```

## Configuring Exception Handling

If your app has a controller-concern named `ControllerExceptionsConcern` then Pairer will automatically pick this up and use it. For an example on how to implement a decent exception handler for your app please see the following blog article that I have written on the topic, https://westonganger.com/posts/properly-implement-error-exception-handling-for-your-rails-controllers

## Development

Run migrations using: `rails db:migrate`

Run server using: `bin/dev` or `cd test/dummy/; rails s`

## Testing

```
bundle exec rspec
```

We test multiple versions of `Rails` using the `appraisal` gem. Please use the following steps to test using `appraisal`.

1. `bundle exec appraisal install`
2. `bundle exec appraisal rake test`
