include_recipe 'postgresql::libpq'
include_recipe 'postgresql::postgis'
include_recipe 'postgresql::server'

package 'git'
package 'language-pack-fi'

postgresql_user 'regularroutes' do
  login true
  password node[:regularroutes][:db_password]
end

postgresql_database 'regularroutes' do
  owner 'regularroutes'
  encoding 'UTF-8'
end

postgresql_extension 'postgis' do
  database 'regularroutes'
end

user node['regularroutes']['user'] do
  system true
  shell '/bin/false'
end

directory '/opt/regularroutes' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end
