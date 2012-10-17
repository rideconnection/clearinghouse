source 'https://rubygems.org'

gem 'capistrano'
gem 'capistrano-ext'
gem 'rails', '3.2.8'
gem 'rvm-capistrano'
gem 'pg'

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
gem 'jquery-rails'

group :test, :development do
  gem 'rails-erd'
  gem 'rspec-rails'
  gem 'ruby-debug19'

  # SQLite
  gem 'sqlite3'
  gem 'activerecord-spatialite-adapter'
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server
# gem 'unicorn'

# To use debugger
# gem 'debugger'

