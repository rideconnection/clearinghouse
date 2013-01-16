source 'https://rubygems.org'

gem 'capistrano'
gem 'capistrano-ext'
gem 'pg'
gem 'rails', '3.2.8'
gem 'rvm-capistrano'

# PostgreSQL hstore support
gem 'activerecord-postgres-hstore',
    git: 'git://github.com/softa/activerecord-postgres-hstore.git'

# Geospatial support
gem 'rgeo'
gem 'activerecord-postgis-adapter'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'audited'
gem 'audited-activerecord', '~> 3.0'
gem 'cancan', '~> 1.6.8'
gem 'devise', '~> 2.1'
gem 'jquery-rails'
gem 'seedbank'
gem 'time_of_day'

# API web service
gem 'grape', '~> 0.2.2'

# Javascript engine
gem 'therubyracer'

group :development do
  gem 'rails-erd'
  gem 'thin'
end

group :test do
  gem "accept_values_for", "~> 0.4.3"
  gem 'capybara'
  gem 'database_cleaner'
  gem 'launchy'
  gem 'rspec-rails'
end

group :test, :development do
  gem 'debugger'
  gem 'factory_girl_rails', '~> 4.1.0'
  gem 'minitest-rails', git: 'git://github.com/blowmage/minitest-rails.git'
  gem 'minitest-rails-capybara',
    git: 'git://github.com/blowmage/minitest-rails-capybara.git'
  gem 'spork-rails'
  gem 'spork-testunit', git: 'git://github.com/sporkrb/spork-testunit.git'
  gem 'spork-minitest', git: 'git://github.com/semaperepelitsa/spork-minitest.git'
  gem 'turn'
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server
# gem 'unicorn'
