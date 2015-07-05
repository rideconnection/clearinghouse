clearinghouse
=============

This is the transportation clearinghouse application, developed by Ride
Connection to promote communication and sharing of resources between
transportation service providers.

Development Environment
-----------------------

This application depends on PostgreSQL for its useful extensions: fuzzy string
match, spatial types and operations, and hstore (key/value store).  It uses
the RGeo gem in combination with the PostGIS extensions for spatial support.

SQLite has a geospatial extension called SpatiaLite, but it does not have the
fuzzy match or key/value storage extensions, so we don't use it in development.

Setting up the development environment:

0. Prerequsites:
   - On OS X, prerequisites can be installed with Homebrew (http://brew.sh).
   - RVM (Ruby Version Manager)
   - PostgreSQL (up to 9.4 tested) and system packages, e.g.:
         apt-get install postgresql-9.4 postgresql-contrib-9.4 \
                         postgresql-9.4-postgis postgresql-server-dev-9.4 \
                         build-essential

1. Install your Ruby environment:
   - rvm pkg install zlib
   - rvm install ruby-2.2.2
   - Clone project from GitHub.
   - cd into directory, rvm automatically switches to correct Ruby and gemset.
   - gem install bundler
   - bundle install
 
2. Create the clearinghouse user and database template:

    $ sudo -u postgres -i
    $ psql

And run the following commands:

    CREATE ROLE clearinghouse WITH CREATEDB LOGIN PASSWORD 'clearinghouse';

    CREATE DATABASE template_clearinghouse;
    UPDATE pg_database SET datistemplate = TRUE WHERE datname =
        'template_clearinghouse';
    
    \c template_clearinghouse

    -- May produce: ERROR:  language "plpgsql" already exists
    -- This is ok.
    CREATE LANGUAGE plpgsql;
    
    -- Install PostGIS (your file paths may vary)
    -- For Brew installations, use the path /usr/local/share/postgis/
    \i /usr/share/postgresql/9.4/contrib/postgis-2.1/postgis.sql
    \i /usr/share/postgresql/9.4/contrib/postgis-2.1/spatial_ref_sys.sql
    GRANT ALL ON geometry_columns TO PUBLIC;
    GRANT ALL ON geography_columns TO PUBLIC;
    GRANT ALL ON spatial_ref_sys TO PUBLIC;
    -- You may need these to avoid persmissions problems with test suites
    ALTER TABLE geometry_columns OWNER TO clearinghouse;
    ALTER TABLE spatial_ref_sys OWNER TO clearinghouse;

    CREATE EXTENSION fuzzystrmatch;
    CREATE EXTENSION hstore;
    
    -- Freeze rows in the database to avoid transaction ID wraparound issues
    VACUUM FREEZE;

We now have a database template called `template_clearinghouse` that can be
used to create new databases with these extensions already installed.

3. Copy config/database.yml.example to config/database.yml and edit as needed.

4. Create your development and test databases: rake db:setup

5. Ensure the test suite passes.  See "Testing" below. 

Seeding your development database
---------------------------------

Run `rake db:seed` to add some starter data. Note that this is automatically 
done when you run the `db:setup` rake task. Run `rake -T db:seed` to see other
seeding options.

Generating ER diagram
---------------------

If you'd like to see an ER diagram based on the current state of the
application's models, you can run:

    rake erd

You may need to install the graphviz library to generate the diagram.

which will produce a file called 'erd.pdf' in the current directory.

Testing
-------

All tests are implemented with minitest.  Run them all with:

    bundle exec rake test

To run an individual minitest test:

    cd <project root directory>
    ruby -Ilib -Itest path/to/test_file.rb

Deployment
==========

This application uses capistrano for deployment.  Check out config/deploy.rb 
and config/deploy/ for basic deployment recipes and configuration.

Deployment uses key-based authentication. To deploy, you'll need to add your 
public key on the staging/production servers so you can run commands as the 
"deployer" user.

To set this up, talk to another developer to get your public key on the 
machines. If you need to do system administration on the servers, you'll need 
your own user account set up as well.

On the server, copy secrets.yml from the project to: /home/deployer/rails/clearinghouse/shared/config

Edit secrets.yml and add random keys for secret_key_base and devise_secret_key
in the production section ("rake secret" can be used to generate random keys).
It may be necessary to install Ruby 2.2.2 and bundler on the server.

Once you have SSH access as deployer, you can deploy:

  run: `cap [staging|production] deploy`

To migrate the database, run:
  run: `cap [staging|production] deploy:migrate`

Run cap -T for more command documentation.

Remember to push your changes to the main repository first, since the deploy
process pulls from there.  

Known Issues
============

Current known issues can be found at https://github.com/rideconnection/clearinghouse/wiki/Known-Issues.
