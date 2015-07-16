# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'clearinghouse'
set :repo_url, 'git://github.com/rideconnection/clearinghouse.git'
set :deploy_via, :remote_cache

# Set :deploy_to in the deploy target files since staging and production server 
# setups are much different
# set :deploy_to, ''

# RVM options
set :rvm_type, :user
set :rvm_ruby_version, 'ruby-2.2.2@clearinghouse'
set :rvm_roles, [:app, :web]

# Rails options
set :conditionally_migrate, false

# Whenever options
set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }
set :whenever_roles, [:db, :app]

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :info

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/app_config.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 20

namespace :deploy do
  after :publishing, :restart
  namespace :assets do
    before :precompile, :link_djw_assets
  end
end
