set :branch, 'master'
set :rvm_ruby_version, 'ruby-2.2.2@clearinghouse'
set :passenger_rvm_ruby_version, 'ruby-2.2.2@global'
set :deploy_to, '/home/deployer/rails/clearinghouse'
set :default_env, { "RAILS_RELATIVE_URL_ROOT" => "/clearinghouse" }

# capistrano-rails directives
set :rails_env, 'staging'
set :assets_roles, [:web, :app]
set :migration_role, [:db]
set :conditionally_migrate, true

server 'ridestage.panopticdev.com', roles: [:app, :web, :db], user: 'deployer'
