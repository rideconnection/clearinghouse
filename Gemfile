source 'https://rubygems.org'

gem 'capistrano'
gem 'capistrano-ext'
gem 'pg'
gem 'rails', '~> 3.2'
gem 'rvm-capistrano'

# PostgreSQL hstore support
# Locking this down to 0.6.0 until this is fixed:
# https://github.com/engageis/activerecord-postgres-hstore/issues/83
gem 'activerecord-postgres-hstore', '0.6.0'

# PostgreSQL array support 
gem 'activerecord-postgres-array', '~> 0.0'

# Geospatial support
gem 'rgeo'
gem 'activerecord-postgis-adapter', '~> 0.5'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2'
  gem 'coffee-rails', '~> 3.2'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0'
end

gem 'audited', '~> 3.0'
gem 'audited-activerecord', '~> 3.0'
gem 'cancan', '~> 1.6'
gem 'devise', '~> 2.2'
gem 'jquery-rails', '~> 2.1'
gem 'seedbank', '~> 0.2'
gem 'time_of_day', '~> 0.1'

# API web service
gem 'grape', '~> 0.2.0'

# Javascript engine
gem 'therubyracer', '~> 0.11'

group :development do
  gem 'rails-erd'
  gem 'thin'
end

group :test do
  gem 'accept_values_for'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'launchy'
  gem 'rspec-rails'
end

group :test, :development do
  gem 'debugger'
  gem 'factory_girl_rails'
  gem 'minitest-rails', git: 'git://github.com/blowmage/minitest-rails.git'
  gem 'minitest-rails-capybara',
    git: 'git://github.com/blowmage/minitest-rails-capybara.git'
  gem 'rspec-rails'
  gem 'spork-rails'
  gem 'spork-testunit', git: 'git://github.com/sporkrb/spork-testunit.git'
  gem 'spork-minitest', git: 'git://github.com/semaperepelitsa/spork-minitest.git'
  gem 'turn', :require => false
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0'

# Use unicorn as the app server
# gem 'unicorn'
