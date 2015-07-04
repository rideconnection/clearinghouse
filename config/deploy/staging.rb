require "rvm/capistrano"

set :branch, "master"
set :rvm_ruby_string, 'ruby-2.2.2@clearinghouse'
set :rails_env, "staging"
set :deploy_to, "/home/deployer/rails/clearinghouse"
role :web, "184.154.158.74"
role :app, "184.154.158.74"
role :db,  "184.154.158.74", :primary => true # This is where Rails migrations will run

before "deploy:assets:precompile", :link_secrets_yml
