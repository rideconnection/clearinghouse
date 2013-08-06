# Bundler and RVM integrations
require 'bundler/capistrano'
require "delayed/recipes" 

set :stages, %w(staging production)
require 'capistrano/ext/multistage'

set :application, "Clearinghouse"
set :repository,  "http://github.com/rideconnection/clearinghouse.git"

set :scm, :git
set :deploy_via, :remote_cache

set :user, "deployer"  # The server's user for deployments
set :use_sudo, false

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

task :copy_database_yml do
  puts "    Copy database.yml file"
  run  "cp #{latest_release}/config/database.yml.example #{latest_release}/config/database.yml"
end

task :link_pids_folder do
  puts "    Link in pids folder"
  run  "mkdir -p #{deploy_to}/shared/pids"
  run  "ln -nFs #{deploy_to}/shared/pids #{latest_release}/pids"
end

task :link_djw_assets_folder do
  puts "    Link in DelayedJobWeb assets folder"
  run "ln -nfs `bundle show delayed_job_web`/lib/delayed_job_web/application/public #{latest_release}/public/job_queue"
end

task :link_database_yml do
  puts "    Link in database.yml file"
  run  "ln -nfs #{deploy_to}/shared/config/database.yml #{latest_release}/config/database.yml"
  puts "    Link in app_config.yml file"
  run  "ln -nfs #{deploy_to}/shared/config/app_config.yml #{latest_release}/config/app_config.yml"
end

before "deploy:assets:precompile", :copy_database_yml
before "deploy:assets:precompile", :link_pids_folder
before "deploy:assets:precompile", :link_djw_assets_folder
after  "deploy:stop",    "delayed_job:stop"
after  "deploy:start",   "delayed_job:start"
after  "deploy:restart", "delayed_job:restart"
