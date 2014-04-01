name "base_server"
description "Builds a web server for use with Rails apps"
run_list( "recipe[ruby_installer]", "recipe[openssl]", "recipe[build-essential]" )