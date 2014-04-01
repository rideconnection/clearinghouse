name "web_server"
description "Builds a web server for Rails apps on Passenger"
run_list( "recipe[apache2]", "recipe[passenger_apache2]", "recipe[postgresql::client]" )

