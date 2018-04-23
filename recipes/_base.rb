include_recipe 'locale::default'

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
