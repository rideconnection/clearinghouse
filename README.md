clearinghouse
=============

This is the transportation clearinghouse application, developed by Ride
Connection to promote communication and sharing of resources between
transportation service providers.

Development Environment
-----------------------

The Gemfile is currently setup with the assumption that you will use SQLite in
your development environment and PostgreSQL on the deployed server.  This
application uses geospatial database extensions that are available for each of
these databases (SpatiaLite and PostGIS respectively) in combination with the
RGeo Ruby gem.

(The use of SQLite may change in the future if it is unable to support all the
features of this application.)

Setting up the development environment:

0. Install RVM if you do not already have it.

1. Install your Ruby environment:
   - Install a JavaScript runtime, for example:
       apt-get install nodejs
   - Install SQLite and SpatiaLite, for example:
       apt-get install sqlite3 libsqlite3-dev libspatialite-dev
   - Trust the local .rvmrc file when you enter this repository directory.
   - rvm install ruby-1.9.3-p286
   - gem install bundler
   - bundle install

2. Create your config/database.yml with a development and test database:

    development:
      adapter: spatialite
      database: db/development.sqlite3
      pool: 5
      timeout: 5000
   
    test:
      adapter: spatialite
      database: db/test.sqlite3
      pool: 5
      timeout: 5000

3. Create your development database: rake db:setup

4. Ensure the test suite passes: rake spec

Generating ER diagram
---------------------

If you'd like to see an ER diagram based on the current state of the
application's models, you can run:

    rake erd

which will produce a file called 'erd.pdf' in the current directory.
