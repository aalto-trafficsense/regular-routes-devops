regular-routes DevOps repository
================================

One-time setup for the development machine
------------------------------------------

1. Install [Vagrant](https://www.vagrantup.com/downloads.html)

2. Install [Chef Development Kit](https://downloads.getchef.com/chef-dk/)

3. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

4. Install Vagrant Berkshelf plugin

        vagrant plugin install vagrant-berkshelf

Setting up a development virtual machine
----------------------------------------

Run Vagrant in the devops repository directory (where Vagrantfile is)

    vagrant up


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
