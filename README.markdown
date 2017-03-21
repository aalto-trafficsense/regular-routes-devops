regular-routes DevOps repository
================================

These instructions assume the use of [Chef](https://www.chef.io/) for installation. It is also assumed that you have access to:

1. A local computer.
1. A server. Temporary servers on e.g. [Digital Ocean](https://www.digitalocean.com/) can be used as fully featured TrafficSense servers for e.g. waypoint generation or client testing.

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
      * _Alternative: `berks vendor <path>`creates the files directly to <path>. One good path is `..` But BEWARE, this may cleanup your whole directory structure._
1. Copy the newly generated cookbook package from your local workstation to the target server  
    * `$ scp cookbooks-1432555542.tar.gz user@host:.`

On your server:

1. Login (e.g. with SSH)
1. Create and cd `regularroutes-cookbooks`:
    * `$ cd /opt`
    * `$ mkdir regularroutes-cookbooks`
    * `$ cd regularroutes-cookbooks`
1. Unzip the cookbook package in the new directory
    * `$ tar xfz ~/cookbooks-1432555542.tar.gz`
1. Run a preparation script for initial setup:
    * `$ cookbooks/regularroutes/init.sh`
    *  _Note: Only needed for a new server, not updates._


B: Generating waypoints from OSM
--------------------------------

Generate a table of waypoints (=crossings) using a map from [OSM](http://www.openstreetmap.org/). The waypoint table has to be present in a running system, but at this time (21.3.2017) no functions depend on the availability of waypoints from a particular area.

Waypoint generation is the heaviest operation in the process, with > 2 GB memory and minimum Ubuntu v. 14 required. If you have a lightweight server, waypoint generation on a temporary server may be a good idea. On an 8 CPU / 16GB server waypoint generation from Finland took 23 mins.

If you have a set of waypoints from your target area, you may skip to step C.

1. In the `/opt/regularroutes-cookbooks` directory create a json text file called `regularroutes-wpts.json` based on the following template:

        ```
	   {
           "regularroutes": {  
             "db_password": "<password: if new install, make up a new one>",  
             "osm_url": "http://download.geofabrik.de/europe/finland-latest.osm.pbf"  
           },  
          "run_list": ["recipe[regularroutes::osm]"]  
        }
        ``` 

1. Make sure chef has access to the file:
    * `$ sudo chgrp lerero regularroutes-wpts.json`
    * `$ sudo chmod 0640 regularroutes-wpts.json`
1. Generate waypoints (run osm recipe in local mode)  
    * `$ cd /opt/regularroutes-cookbooks/cookbooks`
    * `$ sudo chef-client --local-mode -j ../regularroutes-wpts.json`  
1. *IF* waypoint generation was done on another server than the intended production server, package and transfer the resulting osm database to the production server:
    * `$ pg_dump -h 127.0.0.1 -U regularroutes -W regularroutes -F t > my_database.dump`
    * _TBD: Whether pg_dumpall would be better?_
    * Pack: `gzip my_database.dump`
    * Transfer `my_database.dump.gz` to your intended TrafficSense server e.g. with scp.
    * Unpack: `gunzip my_database.dump.gz`
    * Restore the database: `pg_restore -h 127.0.0.1 -U regularroutes -W -d regularroutes my_database.dump`
    * _Another way with text-format dump to be tested_

_Note: If a separate server was used just for database population, it is no longer needed after this step._

Logs will be in `/var/log/upstart/` (upstart) or `journalctl --unit regularroutes-api` and similar (systemd)


C: Setting up a TrafficSense server
-----------------------------------

Set up and start the actual regular-routes (TrafficSense) server.

1. Generate the necessary keys on the [Google developer console](https://console.developers.google.com)
     * If no project available: Set up a new project
     * Fill in the "Product name" field (to be shown to users at login-time) on "APIs & auth" / "Credentials" / "OAuth consent screen"
     * Enable "Google Maps JavaScript API" under "APIs & Auth" / "APIs"
     * Generate two credentials under "APIs & Auth" / "Credentials" / "Credentials": "Add credentials" as follows
     * 1. OAuth web client ID, which the server will use towards Google APIs: "OAuth 2.0 client ID" with the following information:
        * Application type: Web application.
        * `Authorized JavaScript origins`
           * http://your.server.url
           * http://localhost:5000
        * `Authorized redirect URIs` should fill in automatically.
        * Press "Create"
        * Select the generated Web client ID (default "Web client 1") and download a JSON-version of the _client secret_ by pressing "Download JSON" and saving the file as "client_secrets.json" to `/opt/regularroutes` on your server 
        * _Note: the "Client ID" (looks like "7948743243-hsuefse3hisefssef.apps.googleuser...") is also needed for building a [TrafficSense client](https://github.com/aalto-trafficsense/trafficsense-android). If building a corresponding client, the ID can be copied now._
     * 2. Browser API key to be used for Google maps access through the server: "API Key"
        * Select "Browser key". The default name will be "Browser key 1"
        * Enter a host name like `my.server.url/*` into the "Accept requests from these HTTP referrers" field
        * Press "Create"
        * Copy the "Key" (looks like "AIzaSjs8iSef...") for inclusion to the "maps_api_key" of your `regularroutes-srvr.json`file, to be generated in the following steps.
     * _Note: A third credential and another API are needed for the [client](https://github.com/aalto-trafficsense/trafficsense-android). If configuring both, it is practical to generate/enable them now._
1. For labeling places using reverse geocoding, configure the "reverse_geocoding_uri_template" URL (e.g. `https://search.mapzen.com/v1/reverse?api_key=API_KEY&sources=osm&size=20&point.lat={lat}&point.lon={lon}` with your APIKEY substituted) and "reverse_geocoding_queries_per_second" limit in the `regularroutes-srvr.json` file.
1. For push messaging to clients through Firebase, import your Google developer console project into [Firebase](https://console.firebase.google.com/)
     * The `google-services.json` file generated by the Firebase console is needed also for the [TrafficSense client](https://github.com/aalto-trafficsense/trafficsense-android). If building a new client, extract the file now.
     * The Firebase server key will be needed to generate the JSON-file below
1. In the `/opt/regularroutes-cookbooks` directory create a json text file called `regularroutes-srvr.json` based on the following template:

        ```
	   {
           "regularroutes": {  
              "db_password": "<password; must be same as for B above>",
              "maps_api_key" : "<created in Google console>",
              "fmi_api_key" : "<request from the [Finnish Meteorological Institute](https://en.ilmatieteenlaitos.fi/open-data)>",
              "firebase_key" : "<[Firebase console](https://console.firebase.google.com/) Settings -> Project Settings -> Cloud messaging -> Project Credentials -> Server key>",
              "mass_transit_live_keep_days" : "<days to store mass transit data obtained from Helsinki Regional Traffic>",  
              "gmail_from" : "<a gmail account the server sends email from (currently in the case a user presses the cancel participation button)>",
              "gmail_pwd" : "<the password for the above gmail account>",
              "email_to" : "<the email address where mail from the above address is sent>",
              "reverse_geocoding_uri_template" : "<url to pelias instance>",
              "reverse_geocoding_queries_per_second" : "<integer limit>",
              "server_branch": "<github regular-routes-server branch name to install, typically: master>"
           },  
           "run_list": ["recipe[regularroutes]"]  
        }
        ```

1. Setup and start the production server (run default recipe in local mode)  
    * `$ cd /opt/regularroutes-cookbooks/cookbooks`
    * `$ sudo chef-client --local-mode -j ../regularroutes-srvr.json`
    * If the script concludes without fatal errors, the server should be up and running.
1. If needed, individual services can be stopped, started and re-started with
    * `sudo restart regularroutes-api` (upstart) or `sudo systemctl restart regularroutes-api` (systemd)
    * `restart` can be replaced with `stop`, `start` etc.
    * `regularroutes-api` can be replaced with `regularroutes-site`, `regularroutes-dev` or `regularroutes-scheduler`. The functions of the different components are described in the [regular-routes-server readme](https://github.com/aalto-trafficsense/regular-routes-server/blob/master/README.md).

Logs will be in `/var/log/upstart/` (upstart) or `journalctl --unit regularroutes-api` and similar (systemd)

D: Setting up local development server using Virtualbox and Vagrant
-------------------------------------------------------------------

1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
1. Install [Vagrant](https://www.vagrantup.com/downloads.html)
1. Install Vagrant Berkshelf plugin  
        `vagrant plugin install vagrant-berkshelf`  
1. Run Vagrant in the devops repository directory (where Vagrantfile is)  
        `vagrant up`  

*Note! No need to run Berks or Chef manually since Vagrantfile specifies the Chef Cookbook used to setup server*


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
** -s (slim Mode, recommended)
** -H (host for db)
** -P (db service port)
** -U (db user)
** -d (db name)
** -W (force asking password), in this setup username/password are the same


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
