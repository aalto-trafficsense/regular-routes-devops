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
    * Enter the new vagrant guest machine `vagrant ssh`
    * Restore the backup: `$ pg_restore --clean -h 127.0.0.1 -U regularroutes -d regularroutes /vagrant/setup-files/regularroutes_dump_full.tar`
    * (A bunch of errors will be shown because user regularroutes does not have privileges to drop and re-create some roles and because restore is trying to drop all the tables which don't exist yet. Currently 191 errors; should be ok.)
1. Start the regularroutes services
    * Manually inside the guest `$ sudo systemctl start regularroutes-site` etc.
    * Or by running '$ vagrant reload' from the host
1. Test the installation
    * E.g. by logging into `localhost:5000` from a browser in the host, checking the database etc.
1. Upgrade the Vagrant migration test server
    * Two ways to install the new version: With Vagrant (using the host machine) or without vagrant (from inside the guest machine).
    * Recommended to use the same method that will be used in the actual server installation.
1. Checkout a `regular-routes-devops` branch for chef14
    * `$ git checkout --track origin/chef14_upgrade` (note: later to be merged into the master branch)
    * $ rm Berksfile.lock from the regular-routes-devops directory. Otherwise the old and new Chef dependencies will conflict.
1. With Vagrant
    * In `setup-files/regularroutes-srvr.json` edit `"server-branch"` value to point to the new branch (e.g. `chef14_upgrade`) for the server.
1. Without Vagrant
    * Package new cookbooks in your local environment ('$ berks package' in the devops directory)
    * In Vagrant guest machine `opt/regularroutes-cookbooks/regularroutes-srvr.json` edit `"server-branch"` value to point to the new branch (e.g. `chef14_upgrade`) for the server.
1. Consider disk space
    * The pre-migration script or the new installation branch do not delete the old database.
    * If low on disk space, consider dropping some big and non-critical tables, e.g. waypoints, roads, roads_waypoints would need to be re-generated periodically anyway.
    * Also device_data_filtered, global_statistics, leg_ends, leg_waypoints, modes, places, travelled_distances and trips can be re-generated, although in the absence of old mass_transit_data the recognized trips would not be identical.
    * If all old trip recognitions are kept, mass_transit_data is not very critical.
    * Remember to `VACUUM FULL;`
1. Run the pre-migration script
    * NOTE: The pre-migration script prudently takes another dump from the database. Since we already have one in place, which is perfectly good for testing, consider commenting out the `pg_dump` line during testing to save time and disk space.
    * In Vagrant guest machine: `$ /vagrant/migration/pre-migration.sh`
1. Stop the old postgres
    * Check correct version and cluster with `$ pg_lsclusters`
    * Stop the correct version, e.g. `$ pg_ctlcluster 9.4 main stop`
1. With Vagrant
    * Provision the new version from host machine: `$ vagrant provision`
1. Without Vagrant
   * Package the cookbooks in the host machine: `berks package`
   * In the guest machine `cd /opt/regularroutes-cookbooks`
   * Unpack the cookbooks: `$ sudo tar xfz /vagrant/cookbooks-1524731107.tar.gz`
   * '$ cd cookbooks' (first `$ sudo su` if needed)
   * Run the init-script of the new branch: `regularroutes/init.sh` (updates libraries, chef etc.)
   * Run the first part of installation `$ (sudo) chef-client --local-mode -j ../regularroutes-srvr.json -o regularroutes::srvr1`
1. Check the psql and (virtualenv) python versions to confirm that migration has taken place
1. Restore the backup
    * In guest machine: `$ pg_restore --clean -h 127.0.0.1 -U regularroutes -d regularroutes /vagrant/setup-files/regularroutes_dump_full.tar`
1. Start the regularroutes-services
   * Either manually from the guest machine
   * Or with `$ sudo chef-client --local-mode -j ../regularroutes-srvr.json -o regularroutes::srvr2`
   * Or `$ vagrant reload` from the host machine
1. Test that the database restored properly and everything is working
    * If you need several iterations, remember to '$ rm Berkshelf.lock' when changing between old and new - otherwise there will be dependency conflicts.
1. Do it for real
    * Make sure you have a backup somewhere if everything fails.
    * Remember the points about disk space.
    * This time the pg_dump should be extracted after stopping the regularroutes services but before stopping postgres, so letting the pg_dump run in `pre-migration.sh` may make sense.
    * If using the default dump location with `pre-migration.sh`, also `post-migration.sh` can be run for pg_restore.
