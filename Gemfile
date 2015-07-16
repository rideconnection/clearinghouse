source "https://rubygems.org"

gem "pg"
gem "rails", "~> 4.2.1"

# Geospatial support
gem "rgeo"
gem "activerecord-postgis-adapter", "~> 3.0.0"

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem "therubyracer", :require => "v8", :platforms => :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem "audited", "~> 4.2.0"
gem "audited-activerecord", "~> 4.2.0"
gem "daemons", "~> 1.2.2"
gem "cancancan", "~> 1.10.1"
gem "delayed_job_active_record", "~> 4.0.3"
gem "delayed_job_web", "~> 1.2.10"
gem "devise", "~> 3.5.1"
gem "devise-async", "~> 0.10.1"
gem "devise_security_extension", "~> 0.9.2"
gem "kaminari", "~> 0.16.3"
gem "rails-settings-cached", "~> 0.4.1"
gem "seedbank", "~> 0.3.0"
gem "whenever", "~> 0.9.4", :require => false

# Rails 4 compatible version of validates_timeliness
gem "jc-validates_timeliness"

# API web service
gem "grape", "~> 0.11.0"
gem "grape-entity", "~> 0.4.5"

# per https://github.com/intridea/grape#rails
gem "hashie-forbidden_attributes"

group :development do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem "rails-erd"
  gem "thin"

  # Use Capistrano for deployment
  gem 'capistrano', '~> 3.4'
  gem 'capistrano-rvm', '~> 0.1', require: false
  gem 'capistrano-rails', '~> 1.1', require: false
  gem 'capistrano-secrets-yml', '~> 1.0', require: false
end

group :test, :development do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  gem "capybara"
  gem "database_cleaner"
  gem "launchy"
  gem "timecop"
  gem "factory_girl_rails"
  gem "minitest-rails", git: "git://github.com/blowmage/minitest-rails.git"
  gem "minitest-rails-capybara", git: "git://github.com/blowmage/minitest-rails-capybara.git"

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'
end
