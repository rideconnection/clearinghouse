name "db_server"
description "Builds a database server using Postgresql"
run_list( "recipe[postgresql::server]" )

