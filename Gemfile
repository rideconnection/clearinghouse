source "https://rubygems.org"

gem "capistrano", require: false
gem "capistrano-ext", require: false
gem "pg"
gem "rails", "~> 4.2.1"
gem "rvm-capistrano", require: false

# PostgreSQL hstore support
# Locking this down to 0.6.0 until this is fixed:
# https://github.com/engageis/activerecord-postgres-hstore/issues/83
gem "activerecord-postgres-hstore", "0.6.0"

# PostgreSQL array support 
gem "activerecord-postgres-array", "~> 0.0.9"

# Geospatial support
gem "rgeo"
gem "activerecord-postgis-adapter", "~> 3.0.0"

# note that Rails 4 no longer has an assets group
gem "sass-rails",   "~> 5.0.3"
gem "uglifier", "~> 2.7.1"
gem "coffee-rails", "~> 4.1.0"

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem "therubyracer", :require => "v8", :platforms => :ruby

gem "audited", "~> 4.2.0"
gem "audited-activerecord", "~> 4.2.0"
gem "cancan", "~> 1.6.10"
gem "daemons", "~> 1.2.2"
gem "delayed_job_active_record", "~> 4.0.3"
gem "delayed_job_web", "~> 1.2.10"
gem "devise", "~> 3.1.2"
gem "devise-async", "~> 0.8.0"
gem "devise_security_extension", "~> 0.9.2"
gem "jquery-rails", "~> 4.0.3"
gem "kaminari", "~> 0.16.3"
gem "rails-settings-cached", "~> 0.4.1"
gem "seedbank", "~> 0.3.0"
gem "validates_timeliness", "~> 3.0.14"
gem "whenever", "~> 0.9.4", :require => false

# API web service
gem "grape", "~> 0.11.0"

group :test, :development, :staging do
  # note: debugger gem no longer supported, see: https://github.com/cldwalker/debugger#known-issues
  gem "factory_girl_rails"
end

group :test, :development do
  gem "minitest-rails", git: "git://github.com/blowmage/minitest-rails.git"
  gem "minitest-rails-capybara", git: "git://github.com/blowmage/minitest-rails-capybara.git"
  # note: removed Spork because Rails 4.1+ has Spring built-in
  gem "turn", :require => false
end

group :development do
  gem "rails-erd"
  gem "thin"
end

group :test do
  gem "capybara"
  gem "database_cleaner"
  gem "launchy"
  gem "timecop"
end

# To use ActiveModel has_secure_password
# gem "bcrypt-ruby", "~> 3.0"

# Use unicorn as the app server
# gem "unicorn"
