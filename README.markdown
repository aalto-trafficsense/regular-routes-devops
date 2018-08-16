regularroutes DevOps repository
===============================

These instructions assume the use of [Chef](https://www.chef.io/) for installation. It is also assumed that you have access to:

1. A local computer.
1. A server, on which you have owner (root) privileges. Temporary servers on e.g. [Digital Ocean](https://www.digitalocean.com/) can be used as fully featured TrafficSense servers for e.g. waypoint generation or client testing.

Setting up a (test) server on [Vagrant](https://www.vagrantup.com/) can be done with one command using the `Vagrantfile` in this directory, please refer to D below.

Migration guidance
------------------

BEWARE!!! This version defaults to PostgreSQL version 10. If you are migrating from a server running on 9.x, the databases between PostgreSQL major versions are _not compatible_. While there is a data migration scheme, it requires both PostgreSQL versions to be simultaneously installed. As our tables are using PostGIS, also the PostGIS installations are required. _Therefore it is highly recommended to first take a `pg_dump` of your current database, test e.g. on a Vagrant server that `pg_restore` works as expected, and only after that run the actual upgrade on a production server!!!_ Also, if you want to wipe your server clean and have an entirely fresh start, remember to put the dump somewhere safe. You have been warned.

Proposals for migration bash-scripts are in the [migration folder](https://github.com/aalto-trafficsense/regular-routes-devops/tree/master/migration). Check the ReadMe, the comments in the `pre-migration` and `post-migration` scripts and consider the suitability of each operation for your environment.

A: Cookbook operations
----------------------

Package the regular-routes-devops cookbook on your local machine and deploy it on the server.

On your local machine:

1. Install [Chef Development Kit](https://downloads.getchef.com/chef-dk/):
    * For Mac OSX install from browser as instructed on the website.
    * For Debian / Ubuntu also command line installation works. Please check the version number, when using the following:  
    * `$ curl -L -O https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chefdk_0.6.0-1_amd64.deb`  
    * `$ sudo dpkg -i chefdk_0.6.0-1_amd64.deb`  
1. Install git if not present
    * `$ apt-get install git`
1. Clone regular-routes-devops repo:  
    * `$ git clone https://github.com/aalto-trafficsense/regular-routes-devops.git`
1. Package the cookbooks (automatically resolves and includes dependencies):
    * `$ cd regular-routes-devops`  
    * `$ berks package`  
       * --> creates a file named something like `cookbooks-1432555542.tar.gz`
       * _Alternative: `berks vendor <path>` creates the files directly to <path>. One good path is `..` But BEWARE, this may cleanup your whole directory structure._
1. Copy the newly generated cookbook package from your local workstation to the target server  
    * `$ scp cookbooks-1432555542.tar.gz user@host:.`

On your server:

1. Login (e.g. with SSH)
1. Create and cd `regularroutes-cookbooks`:
    * `$ cd /opt`
    * `$ sudo mkdir regularroutes-cookbooks`
    * `$ cd regularroutes-cookbooks`
    * _Note: Since these operations are now in a root-owned directory, you may need to enter `$ sudo su` first to have access to the new directory._
1. Unzip the cookbook package in the new directory
    * `$ sudo tar xfz ~/cookbooks-1432555542.tar.gz`
1. Run a preparation script for initial setup:
    * `$ cookbooks/regularroutes/init.sh`
    *  _Note: Only needed for a new server, not updates._


B: Generating waypoints from OSM
--------------------------------

Generate a table of waypoints (=crossings) using a map from [OSM](http://www.openstreetmap.org/). The waypoint table has to be present in a running system, but at this time (2.11.2017) no functions depend on the availability of waypoints from a particular area.

Waypoint generation is the heaviest operation in the process, with > 2 GB memory and minimum Ubuntu v. 14 required. If you have a lightweight server, waypoint generation on a temporary server may be a good idea. On an 8 CPU / 16GB server waypoint generation from Finland took 23 mins.

If you have a set of waypoints from your target area, you may skip to step C.

1. In the `/opt/regularroutes-cookbooks` directory create a json text file called `regularroutes-wpts.json` based on the following template:

       {
         "regularroutes": {  
           "db_password": "<password: if new install, make up a new one>",  
           "osm_url": "http://download.geofabrik.de/europe/finland-latest.osm.pbf"  
         },  
         "run_list": ["recipe[regularroutes::osm]"]  
       }

1. Make sure chef has access to the file:
    * `$ sudo chgrp lerero regularroutes-wpts.json`
    * `$ sudo chmod 0640 regularroutes-wpts.json`
1. Generate waypoints (run osm recipe in local mode)  
    * `$ cd /opt/regularroutes-cookbooks/cookbooks`
    * `$ sudo chef-client --local-mode -j ../regularroutes-wpts.json`
1. *IF* waypoint generation was done on another server than the intended production server, package and save the resulting waypoints table:
    * `$ pg_dump -h 127.0.0.1 -U regularroutes -d regularroutes -F t -t waypoints -t roads -t roads_waypoints > my_waypoints.tar`
    * Pack: `gzip my_waypoints.tar`
    * Transfer `my_waypoints.tar.gz` to your intended production server (or at least a temporary safe location) e.g. with scp.

_Note: If this was a temporary server just for waypoint generation, it is no longer needed after this step._


C: Setting up a TrafficSense server
-----------------------------------

Set up and start the actual regular-routes (TrafficSense) server.

1. Generate the necessary keys on the [Google developer console](https://console.developers.google.com)
     * If no project available: Set up a new project
     * Fill in the "Product name" field (to be shown to users at login-time) on "APIs & auth" / "Credentials" / "OAuth consent screen"
     * Enable "Google Maps JavaScript API" under "APIs & services" / "Dashboard" / "ENABLE APIS AND SERVICES"
     * Generate two credentials under "APIs & services" / "Credentials" / "Credentials": "Add credentials" as follows
     * 1. OAuth web client ID, which the server will use towards Google APIs: "OAuth 2.0 client ID" with the following information:
        * Application type: Web application.
        * `Authorized JavaScript origins`
           * `https://your.server.url` _(https assumes you have a configured SSL certificate, which should be the case)_
           * `http://localhost:5000`
        * `Authorized redirect URIs` should fill in automatically. If not, enter `https://your.server.url/oauth2callback` and `http://localhost:5000/oauth2callback`
        * Press "Create"
        * Select the generated Web client ID (default name "Web client 1") and download a JSON-version of the _client secret_ by pressing "Download JSON" and saving the file as "client_secrets.json" to `/opt/regularroutes` on your server.
        * _Note: the "Client ID" (looks like "7948743243-hsuefse3hisefssef.apps.googleuser...") is also needed for building a [TrafficSense client](https://github.com/aalto-trafficsense/trafficsense-android) `web_client_id_test` or `web_client_id_production`. If building a corresponding client, copy and save the ID now._
        * _Beware: Looks like Google Dev console may no longer include `client_secret` into the client_secrets json-file?!?! If this is the case, it is visible on the console and can be copy-pasted there. The entry in the JSON-file looks like `"client_secret":"l3Tter4ndNumb3rG4rbag3"` and is traditionally placed after `"auth_provider_x509_cert_url"` and before `"redirect_uris"`._
     * 2. Browser API key to be used for Google maps access through the server: "API Key"
        * Select "Browser key". The default name will be "Browser key 1"
        * Enter host names `your.server.url/*` (and `http://localhost:5000` for local development) into the "Accept requests from these HTTP referrers" field
        * Press "Create"
        * Copy the "Key" (looks like "AIzaSjs8iSef...") for inclusion to the "maps_api_key" of your `regularroutes-srvr.json` file, to be generated in the following steps.
     * _Note: A third credential and another API are needed for the [client](https://github.com/aalto-trafficsense/trafficsense-android). If configuring both a server and a client, it is practical to generate/enable them now when the developer console is open._
1. For labeling places using reverse geocoding, configure the "reverse_geocoding_uri_template" URL to point to an instance of [Pelias](https://pelias.io/) (e.g. `https://api.digitransit.fi/geocoding/v1/reverse?sources=osm&size=20&point.lat={lat}&point.lon={lon}`) and the "reverse_geocoding_queries_per_second" limit in the `regularroutes-srvr.json` file.
1. For push messaging to clients through Firebase, import your Google developer console project into [Firebase](https://console.firebase.google.com/)
     * The `google-services.json` file generated by the Firebase console is needed also for the [TrafficSense client](https://github.com/aalto-trafficsense/trafficsense-android). If building a new client, extract the file now.
     * The Firebase server key will be needed to generate the JSON-file below
1. In the `/opt/regularroutes-cookbooks` directory create a json text file called `regularroutes-srvr.json` based on the following template:

       {
           "regularroutes": {  
              "db_password": "<password; must be same as for B above>",
              "maps_api_key" : "<created in Google console>",
              "fmi_api_key" : "<request from the [Finnish Meteorological Institute](https://en.ilmatieteenlaitos.fi/open-data)>",
              "firebase_key" : "<[Firebase console](https://console.firebase.google.com/) Settings -> Project Settings -> Cloud messaging -> Project Credentials -> Server key>",
              "mass_transit_live_keep_days" : "<days to store mass transit data obtained from [DigiTransit](https://digitransit.fi/en/)>",  
              "gmail_from" : "<a gmail account the server sends email from (currently in the case a user presses the cancel participation button)>",
              "gmail_pwd" : "<the password for the above gmail account>",
              "email_to" : "<the email address where mail from the above address is sent>",
              "reverse_geocoding_uri_template" : "<url to pelias instance>",
              "reverse_geocoding_queries_per_second" : "<integer limit>",
              "server_branch": "master <compatible with this devops-branch, for old PSQL 9.x installations use chef12_fix>"
           },  
           "run_list": ["recipe[regularroutes]"]  
       }

1. Make sure chef has access to the file:
    * `$ sudo chgrp lerero regularroutes-srvr.json`
    * `$ sudo chmod 0640 regularroutes-srvr.json`
1. As of April 23rd 2018, PostgreSQL 10 is missing from the Ubuntu default repositories. If that is the case, check [the instructions](https://www.postgresql.org/download/linux/ubuntu/) on how to add the proper repository.
1. Setup and start the production server (run default recipe in local mode)
    * `$ cd /opt/regularroutes-cookbooks/cookbooks`
    * First time: installation should work, but services don't start if the `waypoints` table is missing. Therefore on first execution:
        * Run `$ sudo chef-client --local-mode -j ../regularroutes-srvr.json -o regularroutes::srvr1`
        * Restore (below) or create (above) the waypoints.
        * Run `$ sudo chef-client --local-mode -j ../regularroutes-srvr.json -o regularroutes::srvr2`
    * Once the waypoint-table exists, everything runs with `$ sudo chef-client --local-mode -j ../regularroutes-srvr.json`
    * If the script concludes without fatal errors, the server should be up and running.
1. *IF* waypoint generation was done on another server, restore the information from that database:
    * Transfer `my_waypoints.tar.gz` to the intended TrafficSense server e.g. with scp.
    * Unpack: `gunzip my_waypoints.tar.gz`
    * Restore the database: `pg_restore -h 127.0.0.1 -U regularroutes -W -d regularroutes my_waypoints.tar`
1. To enable HTTPS, configure nginx to use your certificate. See `/etc/nginx/snippets/snakeoil.conf` for an example.
1. Other configurations
    * Check that your server is on the correct timezone. Ubuntu > v. 14: `$ timedatectl status` to check, e.g. `$ sudo timedatectl set-timezone Europe/Helsinki` to set.
    * Check that all locale-settings are in order. Ubuntu: `$ locale` to list. To fix, many operations may be applicable (confirm which ones apply to your installation):
       * `$ sudo apt-get install language-pack-UTF-8`
       * `$ sudo locale-gen UTF-8`
       * `$ apt-cache search "^language-pack-[a-z][a-z]$"`
       * Add to file `/etc/environment` the following lines: `LC_ALL=en_US.UTF-8` and `LANGUAGE=en_US.UTF-8`

If needed, individual services can be stopped, started and re-started with
* `$ sudo restart regularroutes-api` (upstart) or `$ sudo systemctl restart regularroutes-api` (systemd, new installations)
* `restart` can be replaced with `stop`, `start` etc.
* `regularroutes-api` can be replaced with `regularroutes-site`, `regularroutes-dev` or `regularroutes-scheduler`.
* The functions of the different components are described in the [regular-routes-server readme](https://github.com/aalto-trafficsense/regular-routes-server/blob/master/README.md).

Logs will be in `/var/log/upstart/` (upstart) or `$ journalctl --unit regularroutes-api` and similar (systemd)

D: Setting up a local development server using Virtualbox and Vagrant
-------------------------------------------------------------------

1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
    * On OSX + brew: `$ brew cask install virtualbox`
1. Install [Vagrant](https://www.vagrantup.com/downloads.html)
    * On OSX + brew: `$ brew cask install vagrant`
1. Install Vagrant Berkshelf plugin
    * `$ vagrant plugin install vagrant-berkshelf`
1. Create the following configuration files and place them in directory `setup-files` in the devops repository directory (where Vagrantfile is)
    * `client_secrets.json` as instructed in section C above.
    * `regularroutes-srvr.json` as instructed in section C above.
    * if you have a ready-made waypoints dump as instructed in section B above, it should be called `my_waypoints.tar` and placed in `setup-files`
    * if `my_waypoints.tar` is not found, the script will look for `regularroutes-wpts.json` (format as instructed in section B above) and generate the waypoints.
    * if creating waypoints, more memory and a bigger disk than the current defaults are needed. `$ vagrant plugin install vagrant-disksize`, in Vagrantfile uncomment line `config.disksize.size = '50GB'` and increase memory to e.g. `vb.memory = "4096"`.
    * if neither waypoint file is present, the script will continue, but unless the database has been created before, all regularroutes services will fail to start because of the missing waypoints table.
1. Start Vagrant in the devops repository directory  
    * `$ vagrant up`
1. Log into your new server
    * `$ vagrant ssh`
1. Host port 5000 is mapped to guest port 80 in the current `Vagrantfile`, so opening `localhost:5000` in a browser in the host machine should produce the sign-in page of `regularroutes-site`.
    *  Same port as the default in the local server dev environment to minimise changes in Google dev console and client_secrets. Needs to be changed, if local dev environment and vagrant server are executed simultaneously in the same computer.
1. Remember: If everything went well, all services are running and especially `mass_transit_data` will be retrieving content very fast. If this is undesirable, stop the regularroutes-scheduler service.

Note: No need to run Berks or Chef manually, all taken care of by the vagrant-berkshelf plugin and chef_zero provisioner of Vagrant.

Note 2: Vagrant offers server sharing through internet for testing a local copy of the server (not for production!).

In some installations the share plugin is missing. If that is the case, first install the plugin:

`$ vagrant plugin install vagrant-share`

Vagrant share plugin requires [ngrok](https://ngrok.com/download) (https only available in paid plans). Available also over brew for OS X: `brew cask install ngrok`. From host machine `$ vagrant share` will start sharing and print the generated server URL. To add your new server to Google services, go to Google developer console, add the address to Credentials / OAuth 2.0 client IDs / Web application (default name "Web client 1") and API keys / HTTP referrers (default name "Browser key 1"). Load a new `client_secrets.json` and place it into the correct directory (beware, looks like nowadays the "client secret" can be missing from the json-file!). Restart nginx.

E: Importing Open Street map data from crossings-repository
-----------------------------------------------------------

Method alternative to running the waypoint-generation with the chef-script, as explained above, and only does the first step of importing. MJR: Should this be archived somewhere else as obsolete?

* Remarks 1: Waypoint (crossings) data is in Open Street Map (osm) formatting
* Remarks 2: This instructions expects you to have vagrant up and running with PostgreSQL (+PostGIS) database service up & running and port forwarding to db service to port 5432 at localhost

1. Download and **install osm2pgsql** (http://wiki.openstreetmap.org/wiki/Osm2pgsql#Installation)
2. clone crossings repo or just **download the target osm file**
3. **Execute** the following **command** in shell:
```
    osm2pgsql -s -H localhost -P 5432 -U regularroutes -d regularroutes -W <path_to_osm_file>
```
**Wait for osm2pgsql to finish it's job and you are done**

* The parameters for osm2pgsql are:
   * -s (slim Mode, recommended)
   * -H (host for db)
   * -P (db service port)
   * -U (db user)
   * -d (db name)
   * -W (force asking password), in this setup username/password are the same


F: Problem(s) and Solutions
---------------------------
**Problem:**
```
Vagrant::Errors::NetworkDHCPAlreadyAttached: A host only network interface you're attempting to configure via DHCP already has a conflicting host only adapter with DHCP enabled
```

**Solution:**
Execute the following command in shell:
```
VBoxManage dhcpserver remove --netname HostInterfaceNetworking-vboxnet0
```

**Original issue:** https://github.com/mitchellh/vagrant/issues/3083

**Problem:**
The database is created for a wrong key (typically the JSON-file was not found when running chef).

**Solution:**
Either start server creation from scratch or apply the following commands:
$ sudo -u postgres psql
In postgres:
> DROP DATABASE regularroutes ;
> DROP USER regularroutes ;

**Problem:**
Need to copy (scp) files between two machines because there is no direct ssh connectivity to the server.

**Solution:**
Do the scp from the receiving site.
