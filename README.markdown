regular-routes DevOps repository
================================


Setting up a local development server
------------------------------------------

1. Install [Vagrant](https://www.vagrantup.com/downloads.html)
2. Install [Chef Development Kit](https://downloads.getchef.com/chef-dk/)
3. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
4. Install Vagrant Berkshelf plugin  
    `vagrant plugin install vagrant-berkshelf`
5. Run Vagrant in the devops repository directory (where Vagrantfile is)  
    `vagrant up`

*Note! No need to run Chef manually since Vagrantfile specifies the Chef Cookbook used to setup server*

Setting up a remote development server at Digital Ocean
----------------------------------------

1. Setup a new virtual server at [Digital Ocean](https://www.digitalocean.com)
2. Login to server using SSH client
2. Install git:  
    `apt-get install git`
3. Clone regular-routes-devops repo:  
    `git clone https://github.com/aalto-trafficsense/regular-routes-devops.git`
4. [Install Chef client](https://www.chef.io/download-chef-client/):  
    `curl -L https://www.chef.io/chef/install.sh | sudo bash`




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
