include_recipe 'postgresql::postgis'
include_recipe 'postgresql::server'

package 'language-pack-fi'

postgresql_user 'regularroutes' do
  login true
  password 'regularroutes'
end

postgresql_database 'regularroutes' do
  owner 'regularroutes'
  encoding 'UTF-8'
end

postgresql_extension 'postgis' do
  database 'regularroutes'
end
