#!/bin/bash

echo "This migration script should be executed on a regularroutes server."
echo "It is strongly recommended to test dump & restore of current database"
echo "prior to migration."
echo ""

# https://stackoverflow.com/a/1885534/5528498
read -p "Do you want to continue? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo "Stop nginx (web server)"
  sudo systemctl stop nginx

  echo "Stop current regularroutes services"
  sudo systemctl stop regularroutes-scheduler
  sudo systemctl stop regularroutes-api
  sudo systemctl stop regularroutes-site

  echo "Dump the database to a file"
  # NOTE: Test restoration of the dump before starting this operation!
  pg_dump -h 127.0.0.1 -U regularroutes -d regularroutes -F t > ~/regularroutes_dump_full.tar

  echo "Note: This script is not deleting the old postgresql database."

  echo "Clean up some directories to ensure a fresh start for the new installation."

  # The server files will be pulled from git
  sudo rm -rf /opt/regularroutes/server
  # All python libraries have upgraded => better to start a fresh virtualenv.
  # Renaming the old one in case there would be big problems with the
  # installation.
  sudo rm -rf /opt/regularroutes/virtualenv.old
  sudo mv /opt/regularroutes/virtualenv /opt/regularroutes/virtualenv.old

  # Note: If the old 'cookbooks' and 'nodes' are still in /opt/regularroutes-cookbooks,
  # they could also be cleaned up at this point. However, for a quick migration it
  # would be even better to put the new cookbooks in place before starting this script,
  # so not doing anything here now.

  echo "End of script reached. Now install the new regularroutes server."
  echo "Remember to update 'server branch' in regularroutes-srvr.json so that new server code gets downloaded from git."
fi
