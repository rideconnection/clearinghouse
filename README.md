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
   - rvm pkg install zlib
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

3. Copy config/database.yml.example to config/database.yml and edit as needed.

4. Create your development and test databases: rake db:setup

5. Ensure the test suite passes: 
    bundle exec rake spec
    bundle exec rake test:integration

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

Or:
    bundle exec rake test:all

RSpec will use the DRb server by default. The minitest tests need to be run
with the "testdrb" command.  There is a rake task called "test:all" that will
run both of these for you.

Deployment
==========

This application uses capistrano for deployment.  Check out config/deploy.rb 
and config/deploy/ for basic deployment recipes and configuration.

Deployment uses key-based authentication. To deploy, you'll need to add your 
public key on the staging/production servers so you can run commands as the 
"deployer" user.

To set this up, talk to another developer to get your public key on the 
machines. If you need to do system administration on the servers, you'll need 
your own user accout set up as well.

Once you have SSH access as deployer, you can deploy:

  run: `cap [staging|production] deploy`

To migrate the database, run:
  run: `cap [staging|production] deploy:migrate`

Run cap -T for more command documentation.

Remember to push your changes to the main repository first, since the deploy
process pulls from there.  

