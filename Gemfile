source "https://rubygems.org"

gem "capistrano", require: false
gem "capistrano-ext", require: false
gem "pg"
gem "rails", "~> 4.2.1"
gem "rvm-capistrano", require: false

# Geospatial support
gem "rgeo"
gem "activerecord-postgis-adapter"#, "~> 3.0.0"

# Use SCSS for stylesheets
gem 'sass-rails'#, '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'#, '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails'#, '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem "therubyracer", :require => "v8", :platforms => :ruby

# Adding protected_attributes for transition to Rails 4 strong parameters
gem 'protected_attributes'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'#, '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc'#, '~> 0.4.0', group: :doc

gem "audited"#, "~> 4.2.0"
gem "audited-activerecord"#, "~> 4.2.0"
gem "daemons"#, "~> 1.2.2"
gem "cancan"#, "~> 1.6.10"
gem "delayed_job_active_record"#, "~> 4.0.3"
gem "delayed_job_web"#, "~> 1.2.10"
gem "devise"#, "~> 3.5.1"
gem "devise-async"#, "~> 0.10.1"
gem "devise_security_extension"#, "~> 0.9.2"
gem "kaminari"#, "~> 0.16.3"
gem "rails-settings-cached"#, "~> 0.4.1"
gem "seedbank"#, "~> 0.3.0"
gem "validates_timeliness"#, "~> 3.0.14"
gem "whenever"#, "~> 0.9.4", :require => false

# API web service
gem "grape"#, "~> 0.11.0"

group :test, :development do
  gem "capybara"
  gem "database_cleaner"
  gem "launchy"
  gem "timecop"
  gem "factory_girl_rails"
  gem "minitest-rails", git: "git://github.com/blowmage/minitest-rails.git"
  gem "minitest-rails-capybara", git: "git://github.com/blowmage/minitest-rails-capybara.git"
  gem "turn", :require => false

  # note: debugger gem no longer supported, see: https://github.com/cldwalker/debugger#known-issues
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console'#, '~> 2.0'

  # note: removed Spork because Rails 4.1+ has Spring built-in
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

group :development do
  gem "rails-erd"
  gem "thin"
end

# To use ActiveModel has_secure_password
# gem "bcrypt-ruby", "~> 3.0"

# Use unicorn as the app server
# gem "unicorn"
