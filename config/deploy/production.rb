set :branch, 'production'
set :rvm_ruby_version, 'ruby-2.2.3@clearinghouse'
set :passenger_rvm_ruby_version, 'ruby-2.2.3@passenger'
set :deploy_to, '/home/deploy/rails/clearinghouse'

# capistrano-rails directives
set :rails_env, 'production'
set :assets_roles, [:web, :app]
set :migration_role, [:db]
set :conditionally_migrate, true

server 'ch.rideconnection.org', roles: [:app, :web, :db], user: 'deploy'
