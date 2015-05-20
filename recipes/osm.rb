include_recipe 'regularroutes::_base'
include_recipe 'build-essential::default'

directory '/opt/regularroutes/osm' do
  user node['regularroutes']['user']
  group node['regularroutes']['user']
  mode '0755'
  action :create
end

remote_file '/opt/regularroutes/osm/regularroutes.osm.pbf' do
  source node[:regularroutes][:osm_url]
  user node['regularroutes']['user']
  group node['regularroutes']['user']
  mode '0644'
end

apt_repository 'osm2pgsql' do
  uri          'ppa:gekkio/osm2pgsql'
  distribution node['lsb']['codename']
end

package 'osm2pgsql'

execute 'osm2pgsql' do
  command "osm2pgsql -s -d regularroutes #{node['regularroutes']['osm2pgsql_args']} /opt/regularroutes/osm/regularroutes.osm.pbf"
  cwd '/opt/regularroutes'
  environment(
    'PGHOST' => 'localhost',
    'PGUSER' => 'regularroutes',
    'PGPASSWORD' => node['regularroutes']['db_password']
  )
end

git '/opt/regularroutes/osm/crossings' do
  repository 'https://github.com/aalto-trafficsense/crossings'
  revision 'master'
  action :sync
end

execute 'psql -f /opt/regularroutes/osm/crossings/sql/queries.sql' do
  cwd '/opt/regularroutes/osm/crossings/sql'
  environment(
    'PGHOST' => 'localhost',
    'PGUSER' => 'regularroutes',
    'PGPASSWORD' => node['regularroutes']['db_password']
  )
end
