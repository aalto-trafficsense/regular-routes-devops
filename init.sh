#!/bin/bash

# Preparations for a new regular routes server
# NOT NEEDED for updating an existing server

echo "Updating packages"

sudo apt-get update
sudo apt-get install -y curl

echo "********************"
echo "Installing libraries"

sudo apt-get install -y build-essential python-pip python-dev gfortran libatlas-base-dev libblas-dev liblapack-dev libssl-dev

echo "********************"
echo "Create user 'lerero'"

sudo adduser --system --group lerero

echo "******************************"
echo "Create regularroutes directory"

mkdir /opt/regularroutes
# chef sets the owner, group and chmod for the directory, when running osm or default scripts.

echo "********************************************************************"
echo "Installing a chef-client (https://www.chef.io/download-chef-client/)"
echo "Sample location /opt/chef/ is assumed."

# Installing latest chef no longer works with the current recipes. Commenting out:
# curl -L https://www.chef.io/chef/install.sh | sudo bash

# Install old chef instead:
cd /opt/regularroutes
curl -L -O https://packages.chef.io/files/stable/chefdk/1.5.0/ubuntu/16.04/chefdk_1.5.0-1_amd64.deb
sudo dpkg -i chefdk_1.5.0-1_amd64.deb
rm chefdk_1.5.0-1_amd64.deb
cd -
