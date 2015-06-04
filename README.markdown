regular-routes DevOps repository
================================

Preparing local development environment
------------------------------------------

1. Install [Chef Development Kit](https://downloads.getchef.com/chef-dk/):  
        `curl -L -O https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chefdk_0.6.0-1_amd64.deb`  
        `sudo dpkg -i chefdk_0.6.0-1_amd64.deb`  
1. Install git if not present
        `apt-get install git`
1. Clone regular-routes-devops repo:  
        `git clone https://github.com/aalto-trafficsense/regular-routes-devops.git`

_Note: The local development environment is not recommended for the server._
  
Create the local JSON file
-----------------------------
    {
      "override": {
        "regularroutes": {
          "maps_api_key" : "<create in Google console>",
          "db_password": "<create for the database>"
        }
      },
      "run_list": ["recipe[regularroutes]"]
    }


A: Setting up development server at Digital Ocean
----------------------------------------

1. IN LOCAL DESKTOP: package cookbooks (automatically resolves and includes dependencies)  
        `cd regular-routes-devops`  
        `berks package`  
        --> creates a file named like `cookbooks-1432555542.tar.gz`

        _Alternative: `berks vendor <path>`creates the files directly to <path>. One good path is `..` But BEWARE, this may cleanup your whole directory structure._

1. Setup a new virtual server at [Digital Ocean](https://www.digitalocean.com)
1. Login to server using SSH client
1. [Install Chef client](https://www.chef.io/download-chef-client/):  
        `curl -L https://www.chef.io/chef/install.sh | sudo bash`  
1. IN LOCAL DESKTOP: copy cookbook package from local workstation to newly created server at digital ocean  
        `scp cookbooks-1432555542.tar.gz user@host ...`
1. Update packages by running `apt-get update`
1. Unzip cookbook package  
        `tar xfz cookbooks-1432555542.tar.gz`  
1. Copy regularroutes.json file (content and format describe above) from your local desktop to the server   
1. Populate the OSM database (run osm recipe in local mode)
        `sudo chef-client --local-mode --runlist 'recipe[regularroutes::osm]' -j ../regularroutes.json`  
        _Note: Currently memory-hungry. May fail if the server doesn't have enough memory._
1. Setup server (run default recipe in local mode)
        `sudo chef-client --local-mode --runlist 'recipe[regularroutes]' -j ../regularroutes.json`
1. Copy client_secrets.json to `/opt/regularroutes`
1. Rectify user rights
    chgrp lerero client_secrets.json
    chmod 0640 client_secrets.json
1. Start the server
    restart regularroutes

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
