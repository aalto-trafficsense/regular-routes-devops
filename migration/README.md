Server migration checklist
==========================

1. Starting situation: A python2 regularroutes server with postgresql 9.x database is running. How to check?
    * `$ psql --version` ==> `psql (PostgreSQL) 9.x.y`
    * `$ source /opt/regularroutes/virtualenv/bin/activate` `$ python --version` ==> `Python 2.x.y` `$ deactivate`
1. Make a test dump of the database.
    * `pg_dump -h 127.0.0.1 -U regularroutes -d regularroutes -F t > ~/regularroutes_dump_full.tar`
1. Set up a python2 regularroutes migration test server using e.g. Vagrant
    * Clone regular-routes-devops into a new directory: `$ git clone https://github.com/aalto-trafficsense/regular-routes-devops.git`
    * Enter the directory and checkout remote branch `chef12_fix`:
        * `$ cd regular-routes-devops`
        * `$ git checkout --track origin/chef12_fix`
    * Configure `setup-files`
        * `$ mkdir setup-files`
        * Copy `/opt/regularroutes-cookbooks/regularroutes-srvr.json` from your server to the setup-files directory.
        * Edit `"server-branch"` value to `chef12_fix` so that the correct regular-routes-server branch will be installed.
        * Copy `/opt/regularroutes/client_secrets.json` from your server to the setup-files directory.
        * No need to include any waypoint-dump or configuration files. Starting regularroutes services will fail at the end of the setup, this is ok.
    * `$ vagrant up` in the new `regular-routes-devops` directory.
1. Restore the dump e.g. like this
    * Copy `regularroutes_dump_full.tar` into the `regular-routes-devops/setup-files` directory.
    * Enter the new vagrant server `vagrant ssh`
    * Restore the backup: `$ pg_restore --clean -h 127.0.0.1 -U regularroutes -d regularroutes /vagrant/setup-files/regularroutes_dump_full.tar`
    * (A bunch of errors will be shown because user regularroutes does not have privileges to drop and re-create some roles etc., and because restore is trying to drop all the tables which don't exist yet. Should be ok.)
1. Start the regularroutes services
    * Manually inside the guest `$ sudo systemctl start regularroutes-site` etc.
    * Or by running '$ vagrant reload' from the host
1. Test the installation is working
    * E.g. by logging into `localhost:5000` from a browser in the host.
1. Upgrade the migration test server
    * Two ways to install the new version: With or without vagrant.
    * Recommended to use the same method that will be used in the actual server installation.
1. Checkout a `regular-routes-devops` branch for chef14
    * `$ git checkout --track origin/chef14_upgrade` (note: later to be in master branch)
1. With Vagrant
    * Change `regular-routes-devops` to a branch with the new version, e.g. `chef14_upgrade`
        * In `setup-files/regularroutes-srvr.json` edit `"server-branch"` value to point to `chef14_upgrade` for the server.
1. Without Vagrant
    * Package new cookbooks in your local environment ('$ berks package' in the devops directory)
    * In guest machine `opt/regularroutes-cookbooks/regularroutes-srvr.json` edit `"server-branch"` value to point to `chef14_upgrade` for the server.
1. Run the pre-migration script
    * `$ `
