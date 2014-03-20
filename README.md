# CLEARINGHOUSE CUSTOM CHEF RECIPE

Uses knife, chef-solo and several cookbooks to create a standalone
clearinghouse server.

Tested ONLY on Ubuntu 12.04 LTS.

The stack includes:
-   Ruby 1.9.3, custom-built without RVM
-   PostgreSQL 8.4
-   Apache2
-   Phusion Passenger

## Chef-solo: Further reading:
Find cookbooks http://community.opscode.com/cookbooks

## Server Requirements

Blank Ubuntu 12.04 server machine with root SSH access. You can set
this initial access up by having the root password or by having your
SSH public key on the target server in /root/.ssh/authorized_keys.

## Development Machine Requirements

Make sure on your machine which you are running the chef commands from
that you have ruby, chef & knife-solo installed

    gem install chef -v 11.4.0
    gem install knife-solo -v 0.2.0
    
## Testing your deployment

Prerequisites:

-   Vagrant http://vagrantup.com
-   VirtualBox http://virtualbox.org

With both installed, do this from the project root:

    vagrant up
    
This will download the required Vagrant box (if they haven't been DL'd
already) and provision a couple local VMs. To access them, open a new
terminal tab, `cd` to the project directory, then:

    vagrant ssh 33.33.33.10
    
That will log you into the VM named "ch_web". To access the other VM,
open another terminal, `cd` to the project directory, then:

    vagrant ssh 33.33.33.11

The next step is to prepare them for our recipes. Copy your public SSH 
key (probably in `~/.ssh/id_rsa.pub`), then on each of the VM servers:

    mkdir -p /root/.ssh
    touch /root/.ssh/authorized_keys
    vim /root/.ssh/authorized_keys
    
Append your public key to the end of that file, then save and quit.

Now you can follow along with the directions below, replacing 
`<server-hostname>` with the IP address of the VM machine.

> When you get to `knife solo cook root@<server-hostname>`, you will 
> also need to specify the path to the JSON node file that you want to
> use on that VM. Ex:
>     `knife solo cook root@33.33.33.10 nodes/ch.rideconnection.org.json`

TODO change the nodes to use role-based names so that we always have to
     explicitly specify the node JSON file. Then we can delete the
     caveat above.
     
TODO Revisit everything below here -vvv-

## Prepare server and deploy:

    ./deploy.sh root@<server-hostname>
    knife solo prepare root@<server-hostname>
    knife solo cook root@<server-hostname>

## Set up database on target server:
Currently, this is the one primary step that is done manually.
Typically, you'll load a production database dump when setting up a
server.

First, create a database backup on another system using the pg_dump
command, and use scp or a simliar command to get the generated sql file
onto the target server.
On the target server, as root:

    su postgres
    createdb <database name>
    psql -d <database name> -f /path/to/database_dump.sql

## Deploy Code to Server

This is documented in the master branch, but basically, to get things
going you want to run:

    cap deploy:setup
    cap deploy:cold
    cap deploy:migrations

And you're done!


## SETTING UP NEW SERVERS

Create a new node for a new server:
    cd nodes
    cp ../node-templates/webserver_template.json <Server IP>.json

Edit <Server IP>.json file and change username and password to anything
you like and remove or add cookbooks if you want.
