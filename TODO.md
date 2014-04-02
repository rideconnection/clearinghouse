# TODO

-   The value for `postgresql[:listen_addresses]` in the DB node JSON file 
    isn't being picked up when the postgresql server recipe is run. As a
    result, I've had to change it manually on the server after each time
    we run the Chef scripts. I think I may just be specifying it wrong so
    the defaults aren't being overwritten.

-   I edited cookbooks/postgresql/templates/default/pg_hba.conf.erb to add a
    rule to allow connections from the main webserver. I'm sure there's a way
    to override that default template and use a custom one (maybe from within
    the clearinghouse cookbook) and use a value from the node JSON file.
