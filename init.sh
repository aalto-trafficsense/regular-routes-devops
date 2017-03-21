#!/bin/bash

# Preparations for a new regular routes server
# NOT NEEDED for updating an existing server

echo "*****************"
echo "Updating packages"

sudo apt-get update
sudo apt-get install curl

echo "********************"
echo "Installing libraries"

sudo apt-get install build-essential python-pip python-dev gfortran libatlas-base-dev libblas-dev liblapack-dev libssl-dev

echo "Installing a chef-client (https://www.chef.io/download-chef-client/)"
echo "Sample location /opt/chef/ is assumed."

curl -L https://www.chef.io/chef/install.sh | sudo bash

echo "********************"
echo "Create user 'lerero'"

sudo adduser --system --group lerero

echo "******************************"
echo "Create regularroutes directory"

mkdir /opt/regularroutes
# chef sets the owner, group and chmod, when running osm or default scripts.
