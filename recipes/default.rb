include_recipe 'build-essential::default'

package('ruby-dev') { action :nothing }.run_action(:install)

package 'language-pack-fi'

include_recipe 'database::postgresql'
include_recipe 'postgresql::server'
include_recipe 'postgis::default'

postgresql_connection_info = {:host => 'localhost'}

postgresql_database_user 'regularroutes' do
  connection postgresql_connection_info
  password 'regularroutes'
end

postgresql_database 'regularroutes' do
  connection postgresql_connection_info
  template node['postgis']['template_name']
  owner 'regularroutes'
  action :create
end
