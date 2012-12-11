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
    -- For Brew installations, use the path /usr/local/share/postgis/
    \i /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
    \i /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql
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

which will produce a file called 'erd.pdf' in the current directory.

Testing
-------

We currently have two test suites, you can run them with the commands:

    bundle exec rspec spec
    bundle exec rake test:integration

(This task is defined in lib/tasks/alltests.rake)

Speeding up your tests
----------------------

The spork gem has been included and preconfigured in order to help speed up the 
execution of tests. If you are only going to be running the test suite once or 
need to setup a CI server, you won't want to use spork. But if you will be
running tests frequently, while developing a new feature or refactoring, etc., 
then preloading your test environment into spork will save you a few seconds 
or minutes per test execution.

You'll need two instances of spork for the two test suites:

    bundle exec spork rspec    (in terminal one)
    bundle exec spork minitest (in terminal two)

You can then run the test suites with the commands:

    bundle exec rspec spec
    bundle exec testdrb test/integration/**/*_test.rb

RSpec will use the DRb server by default. The minitest tests need to be run
with the "testdrb" command.  There is a rake task called "test:all" that will
run both of these for you.
