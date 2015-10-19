regular-routes DevOps repository
================================

Preparing a local development environment
------------------------------------------

The local development environment is used for coding new features for the server. The local environment is necessary also for setting up remote servers.

1. Install [Chef Development Kit](https://downloads.getchef.com/chef-dk/):
    * For Mac OSX install from browser as instructed on the website.
    * For Debian / Ubuntu also command line installation works. Please check the version number, when using the following:  
        `curl -L -O https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chefdk_0.6.0-1_amd64.deb`  
        `sudo dpkg -i chefdk_0.6.0-1_amd64.deb`  
1. Install git if not present
        `apt-get install git`
1. Clone regular-routes-devops repo:  
        `git clone https://github.com/aalto-trafficsense/regular-routes-devops.git`

_Note: The local development environment is not recommended for the server._

A: Setting up a remote TrafficSense server
------------------------------------------

These instructions are for setting up servers over a network connection. Remote servers on e.g. [Digital Ocean](https://www.digitalocean.com/) are fully featured TrafficSense servers for temporary testing. Can be used for e.g. database population or client testing against a temporary server. Unless specifically noted otherwise, the same initial steps are needed for setting up both types of servers.

1. Set up the local development environment as instructed above.
1. *If* a new server is needed: Setup a new virtual server e.g. at [Digital Ocean](https://www.digitalocean.com). For database population (e.g. Finland) > 2GB memory is required. On an 8 CPU / 16GB server database population on Finland took 23 mins.
1. In your *local development environment*: package cookbooks (automatically resolves and includes dependencies)  
        `cd regular-routes-devops`  
        `berks package`  
        --> creates a file named something like `cookbooks-1432555542.tar.gz`

        _Alternative: `berks vendor <path>`creates the files directly to <path>. One good path is `..` But BEWARE, this may cleanup your whole directory structure._
1. Copy the newly generated cookbook package from your local workstation to the target server  
        `scp cookbooks-1432555542.tar.gz user@host:.`
1. Login to your server using SSH client
1. [Install Chef client](https://wwan w.chef.io/download-chef-client/):  
        `curl -L https://www.chef.io/chef/install.sh | sudo bash`  
1. Update packages by running `sudo apt-get update`
1. Unzip the cookbook package  
        `tar xfz cookbooks-1432555542.tar.gz`  
1. Generate the necessary keys on the Google developer console
     * [A signing key](https://developer.android.com/tools/publishing/app-signing.html) needs to be made available. If you don't have one yet, manual generation (typically locally) can be done with: `$ keytool -genkey -v -keystore my-release-key.keystore -alias alias_name -keyalg RSA -keysize 2048 -validity 10000 ` A password for the keystore and a key password are needed - remember or write down!
     * Open https://console.developers.google.com
     * Go to APIs & auth / Credentials / Add credentials / API Key / Browser key
     * Enter a host name like `regularroutes.niksula.hut.fi/*` into the HTTP referrers field
     * Generate (under "Add credentials") also a client ID for Web Applications. Requires the following information under "Authorized Javascript origins":
    http://<server URL>
    http://localhost:5000
     * Authorized redirect URIs (OAuth2Callback) should be filled in automatically.
     * Press "Download JSON" (for the Web Applications) to get the JSON-version of the client secret. Select "Client ID for Android Applications". Package name: "fi.aalto.trafficsense.regularroutes". SHA1 generated from the release key.
     * Enable the "Google Maps JavaScript API" under APIs & Auth / APIs
     * Copy the generated API key into the "maps_api_key" into your `regularroutes.json`file, as instructed below.
1. Generate a JSON-file for the keys. Depending on whether you are populating map data on a temporary server or generating a new server, the format is slightly different.
     * For the purpose of *generating waypoints from a map* (`regularroutes-wpts.json`):

    ```{  
      "regularroutes": {  
        "db_password": "<generate for the database>",  
        "osm_url": "http://download.geofabrik.de/europe/finland-latest.osm.pbf"  
      },  
      "run_list": ["recipe[regularroutes::osm]"]  
    }  ```
    
     * For a *production server* (`regularroutes-srvr.json`):

    ```{  
        "regularroutes": {  
          "maps_api_key" : "<created in Google console>",  
          "db_password": "<generate for the database>"  
        },  
      "run_list": ["recipe[regularroutes]"]  
    }```

1. Generate waypoints (run osm recipe in local mode)  
        `sudo chef-client --local-mode -j ../regularroutes-wpts.json`  
        _Note: Does not work on Ubuntu 12.04, requires v. 14 or higher. Also memory-hungry. May fail if the server doesn't have enough memory._
1. *IF* population was done on another server than the intended production server, package and transfer the resulting osm database to the production server:
    * `pg_dump -h 127.0.0.1 -U regularroutes -W regularroutes -F t > my_database.dump`
    * _TBD: Whether pg_dumpall would be better?_
    * Pack: `gzip my_database.dump`
    * Transfer `my_database.dump.gz` to your intended TrafficSense server e.g. with scp.
    * Unpack: `gunzip my_database.dump.gz`
    * Restore the database: `pg_restore -h 127.0.0.1 -U regularroutes -W -d regularroutes my_database.dump`
    * _Another way with text-format dump to be tested_
    * _Note: If a separate server was used just for database population, it is no longer needed after this step._
1. Setup production server (run default recipe in local mode)  
    `sudo chef-client --local-mode -j ../regularroutes-srvr.json`
1. Generate a client_secrets.json in the Google Developer console
    * Set up a product name in the APIs & auth / Credentials / OAuth consent screen
    * APIs & Auth / Credentials / Create an OAuth client id. Application type: Web application. Authorized JavaScript origin & Authorized redirect URIs need two addresses each, as explained [here](https://github.com/aalto-trafficsense/regular-routes-client/blob/master/README.markdown#31-build-new-ids-in-google-developer-console).
    * Copy the returned client_ID to your Android client project. File `regularroutes/src/main/assets/regularroutes.conf`, line web_cl_id.
    * Use the download link on the OAuth 2.0 client ID to download the client_secrets.json
    * Copy client_secrets.json to `/opt/regularroutes` on your server
1. Rectify user rights  
    `cd /out/regularroutes`
    `sudo chgrp lerero client_secrets.json`  
    `sudo chmod 0640 client_secrets.json`  
1. Start the server  
    `sudo restart regularroutes`  

Logs will be in `/var/log/upstart/`

B: Setting up local development server using Virtualbox and Vagrant
------------------------------------------

1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
1. Install [Vagrant](https://www.vagrantup.com/downloads.html)
1. Install Vagrant Berkshelf plugin  
        `vagrant plugin install vagrant-berkshelf`  
1. Run Vagrant in the devops repository directory (where Vagrantfile is)  
        `vagrant up`  

*Note! No need to run Berks or Chef manually since Vagrantfile specifies the Chef Cookbook used to setup server*


Importing Open Street map data from crossings-repository
--------------------------------------------------------

TBD: Explain who needs this and for what.

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


Problem(s) and Solutions
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
