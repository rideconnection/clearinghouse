# TODO upgrade to capistrano v3 syntax!! (See staging file)

set :branch, "production"
set :deploy_to, "/srv/clearinghouse"
set :rails_env, "production"
role :web, "ch.rideconnection.org"
role :app, "ch.rideconnection.org"
role :db,  "ch.rideconnection.org", :primary => true # This is where Rails migrations will run

before "deploy:assets:precompile", :link_secrets_yml
