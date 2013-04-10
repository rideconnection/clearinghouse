set :branch, "master"
set :rvm_ruby_string, '1.9.3-p286@global'
set :deploy_to, "/srv/clearinghouse"
set :rails_env, "production"
role :web, "ch.rideconnection.org"
role :app, "ch.rideconnection.org"
role :db,  "ch.rideconnection.org", :primary => true # This is where Rails migrations will run

