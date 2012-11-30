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
   - RVM
   - PostgreSQL, e.g.:
         apt-get install postgresql postgresql-contrib-9.1 \
                         postgresql-9.1-postgis postgresql-server-dev-9.1

1. Install your Ruby environment:
   - Trust the local .rvmrc file when you enter this repository directory.
   - rvm install ruby-1.9.3-p286
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
    \i /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
    \i /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql
    GRANT ALL ON geometry_columns TO PUBLIC;
    GRANT ALL ON geography_columns TO PUBLIC;
    GRANT ALL ON spatial_ref_sys TO PUBLIC;

    CREATE EXTENSION fuzzystrmatch;
    CREATE EXTENSION hstore;
    
    -- Freeze rows in the database to avoid transaction ID wraparound issues
    VACUUM FREEZE;

We now have a database template called `template_clearinghouse` that can be
used to create new databases with these extensions already installed.

3. Create your config/database.yml with a development and test database:

    common: &common
      adapter: postgis
      host: localhost
      username: clearinghouse
      password: clearinghouse
      template: template_clearinghouse
      min_messages: warning
      pool: 5
      timeout: 5000
    
    development:
      <<: *common
      database: clearinghouse_dev
    
    test:
      <<: *common
      database: clearinghouse_test

4. Create your development and test databases: rake db:setup

5. Ensure the test suite passes: rake spec

Generating ER diagram
---------------------

If you'd like to see an ER diagram based on the current state of the
application's models, you can run:

    rake erd

which will produce a file called 'erd.pdf' in the current directory.

Testing
-------

We are using Rspec for unit testing. You can run the tests using either of the
following commands:

    bundle exec rake test
    bundle exec rspec spec

Speeding up your tests
----------------------

The spork gem has been included and preconfigured in order to help speed up the 
execution of tests. If you are only going to be running the test suite once or 
need to setup a CI server, you won't want to use spork. But if you will be
running tests frequently, while developing a new feature or refactoring, etc., 
then preloading your test environment into spork will save you a few seconds 
or minutes per test execution. To use spork while testing, first boot up spork:

    bundle exec spork

The `--drb` option for rspec has been enabled by default, so the tests will 
automatically use the spork server if it is running. Note that because spork 
preloads your environment, you will have to restart the spork server anytime 
you modify your model or configuration files, or anything else that will be
cached by the Rails server.