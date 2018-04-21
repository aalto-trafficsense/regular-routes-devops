include_recipe 'locale::default'

# node.override['postgresql']['enable_pgdg_yum'] = true
# node.override['postgresql']['version'] = '9.5'
# node.default['postgresql']['config']['data_directory'] = node['postgresql']['dir']
# node.default['postgresql']['client']['packages'] = ["postgresql95", "postgresql95-devel"]
# node.default['postgresql']['server']['packages'] = ["postgresql95-server"]
# node.default['postgresql']['server']['service_name'] = "postgresql-9.5"
# node.default['postgresql']['contrib']['packages'] = ["postgresql95-contrib"]
# node.default['postgresql']['setup_script'] = "postgresql95-setup"
# node.override['postgresql']['password']['postgres'] = node[:regularroutes][:db_password]

# include_recipe 'postgresql::libpq'
# include_recipe 'postgresql::postgis'

# include_recipe 'postgresql::server'

# postgresql_repository 'install' do
#   version '9.5'
# end
#
# postgresql_server_install 'package' do
#   version '9.5'
# end

# postgresql_server_conf 'PostgreSQL Config' do
#   version '9.5'
#   notification :reload
# end

# postgresql_user 'regularroutes' do
#   login true
#   password node[:regularroutes][:db_password]
# end
#

# https://github.com/phlipper/chef-postgresql/blob/master/providers/user.rb
# def user_exists?
#   exists = %(psql -c "SELECT rolname FROM pg_roles WHERE rolname='regularroutes'" | grep 'regularroutes') # rubocop:disable LineLength
#   cmd = Mixlib::ShellOut.new(exists, user: "postgres")
#   cmd.run_command
#   cmd.exitstatus.zero?
# end

# unless user_exists?
#   execute "create postgresql user regularroutes" do # ~FC009
#       user "postgres"
#       command %(psql -c "CREATE ROLE regularroutes WITH LOGIN PASSWORD #{node[:regularroutes][:db_password]};")
#       sensitive true
#   end
# end


# postgresql_database 'regularroutes' do
#   owner 'regularroutes'
#   encoding 'UTF-8'
# end

# https://github.com/phlipper/chef-postgresql/blob/master/providers/database.rb
# def database_exists? # rubocop:disable AbcSize
#   sql = %(SELECT datname from pg_database WHERE datname='regularroutes')
#   exists = %(psql -c "#{sql}" postgres)
#   exists << " | grep regularroutes"
#   cmd = Mixlib::ShellOut.new(exists, user: "postgres")
#   cmd.run_command
#   cmd.exitstatus.zero?
# end

# unless database_exists?
#   execute "create postgresql database regularroutes" do # ~FC009
#       user "postgres"
#       command "createdb -O regularroutes -E UTF-8"
#       sensitive true
#   end
# end


# postgresql_client_install 'postgresql client' do
#   version '9.5'
# end

postgresql 'main' do
  cluster_version '10'
end

# Note: Superuser privileges needed to create extension (postgis)
# If postgis installation recipe support is fixed, superuser priveleges can be removed
postgresql_user 'regularroutes' do
  in_version '10'
  in_cluster 'main'
  encrypted_password node[:regularroutes][:db_password]
  superuser true
end

postgresql_database 'regularroutes' do
  in_version '10'
  in_cluster 'main'
  owner 'regularroutes'
end

# MJR commented out 30.10.2017
# postgresql_extension 'postgis' do
#   database 'regularroutes'
# end

# node.default['postgis']['template_name'] = 'regularroutes'
# include_recipe 'postgis::default'

# pgxn_extension 'postgis' do
#   in_version '9.6'
#   in_cluster 'main'
#   db 'regularroutes'
#   version '2.4'
#   stage 'stable'
# end

apt_package 'postgis' do
  version '2.4.4+dfsg-1.pgdg16.04+1'
  action :install
end

execute "create extension postgis" do
  user "postgres"
  command %(psql -d regularroutes -c "CREATE EXTENSION IF NOT EXISTS postgis;")
  sensitive true
end

execute "revoke regularroutes superuser privileges" do
  user "postgres"
  command %(psql -c "ALTER ROLE regularroutes nosuperuser;")
  sensitive true
end

package 'git'
package 'language-pack-fi'

# Created already in the init-script, because regularroutes-*.json should be in group lerero
# user 'lerero' do
#   system true
#   shell '/bin/false'
# end

directory '/opt/regularroutes' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end
