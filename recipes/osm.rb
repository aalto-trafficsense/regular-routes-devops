include_recipe 'regularroutes::_base'
include_recipe 'build-essential::default'

directory '/opt/regularroutes/osm' do
  owner 'regularroutes'
  group 'regularroutes'
  mode '0755'
  action :create
end

remote_file '/opt/regularroutes/osm/regularroutes.osm.pbf' do
  source node[:regularroutes][:osm_url]
  user 'regularroutes'
  group 'regularroutes'
  mode '0644'
end

# TODO: osm2pgsql and other things
