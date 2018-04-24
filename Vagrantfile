# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'json'
# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.
  config.vm.hostname = "regularroutes"

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "ubuntu/xenial64"
  # config.disksize.size = '50GB'

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    # vb.gui = true

    # Customize the amount of memory on the VM:
    vb.memory = "2048"
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # The path to the Berksfile to use with Vagrant Berkshelf
  # config.berkshelf.berksfile_path = "./Berksfile"

  # Enabling the Berkshelf plugin. To enable this globally, add this configuration
  # option to your ~/.vagrant.d/Vagrantfile file
  config.berkshelf.enabled = true

  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to exclusively install and copy to Vagrant's shelf.
  # config.berkshelf.only = []

  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to skip installing and copying to Vagrant's shelf.
  # config.berkshelf.except = []

  CHEF_VERSION = "14.0.202"

  config.vm.provision "shell", inline: <<-SHELL
    timedatectl set-timezone Europe/Helsinki
    sh -c "echo 'LANGUAGE=en_US.UTF-8\nLC_ALL=en_US.UTF-8\nLC_CTYPE=en_US.UTF-8' >> /etc/default/locale"
    # PostgreSQL 10 is currently not included in the default repos. Add the repo if missing.
    if [ ! -e /etc/apt/sources.list.d/pgdg.list ]; then
      echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" > /etc/apt/sources.list.d/pgdg.list
      wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
    fi
    apt-get update
    # apt-get install -y curl # ubuntu/xenial64 box already has an up-to-date curl, uncomment if a future box doesn't
    apt-get install -y build-essential python3-pip python3-dev python3-venv gfortran libatlas-base-dev libblas-dev liblapack-dev libssl-dev
    adduser --system --group lerero
    # Easier to access systemd-logs afterwards
    adduser vagrant systemd-journal
    cd /opt
    mkdir -p regularroutes
    mkdir -p regularroutes-cookbooks
    cd regularroutes-cookbooks
    # Note: Thus copy of regularroutes-srvr.json is currently not used, but in non-Vagrant installations and
    #       later manual updates it is expected to be in /opt/regularroutes-cookbooks
    cp /vagrant/setup-files/regularroutes-srvr.json /opt/regularroutes-cookbooks
    chgrp lerero regularroutes-srvr.json
    chmod 0640 regularroutes-srvr.json
    cp /vagrant/setup-files/client_secrets.json /opt/regularroutes
    wait
  SHELL
  config.vm.provision :chef_zero do |chef|
    chef.version = CHEF_VERSION
    chef.nodes_path = "temp"
    chef.json = Hash[*JSON.parse(IO.read('setup-files/regularroutes-srvr.json')).first]
    chef.run_list = [
      "recipe[regularroutes::srvr1]"
    ]
  end
  if (not provisioned?) || explicit_provisioning?
    # Extract db_password from JSON and store for command line use
    open("setup-files/.pgpass", 'w') {|f| f.puts "127.0.0.1:5432:regularroutes:regularroutes:" + JSON.parse(IO.read('setup-files/regularroutes-srvr.json'))['regularroutes']['db_password'] }
  end
  config.vm.provision "shell", inline: <<-SHELL
    rm -f /home/vagrant/.pgpass
    mv /vagrant/setup-files/.pgpass /home/vagrant/.pgpass
    chmod 0600 /home/vagrant/.pgpass
    chown vagrant:vagrant /home/vagrant/.pgpass
  SHELL
  # Nicer example checking file existence: https://gist.github.com/mlafeldt/7120176
  if File.exists?('setup-files/my_waypoints.tar')
    # RESTORE PRE-GENERATED WAYPOINTS
    config.vm.provision "shell", inline: <<-SHELL
      su -c "pg_restore -h 127.0.0.1 -U regularroutes -d regularroutes /vagrant/setup-files/my_waypoints.tar" vagrant
      wait
    SHELL
  else
    if File.exists?('setup-files/regularroutes-wpts.json')
      # GENERATE WAYPOINT TABLES
      config.vm.provision "shell", inline: <<-SHELL
        # Note: The copy of regularroutes-wpts.json is not used, but in non-Vagrant installations and
        #       later manual updates it is expected to be in /opt/regularroutes-cookbooks
        cd /opt/regularroutes-cookbooks
        cp /vagrant/setup-files/regularroutes-wpts.json .
        chgrp lerero regularroutes-wpts.json
        chmod 0640 regularroutes-wpts.json
      SHELL
      config.vm.provision :chef_zero do |chef|
        chef.version = CHEF_VERSION
        chef.nodes_path = "temp"
        chef.json = JSON.parse(IO.read('setup-files/regularroutes-wpts.json'))
      end
    end
  end
  config.vm.provision :chef_zero do |chef|
    chef.version = CHEF_VERSION
    chef.nodes_path = "temp"
    chef.run_list = [
      "recipe[regularroutes::srvr2]"
    ]
  end
end

# Credits: https://stackoverflow.com/a/45612332/5528498
def provisioned?(vm_name='default', provider='virtualbox')
  File.exists?(File.join(File.dirname(__FILE__),".vagrant/machines/#{vm_name}/#{provider}/action_provision"))
end

def explicit_provisioning?()
   (ARGV.include?("reload") && ARGV.include?("--provision")) || ARGV.include?("provision")
end
