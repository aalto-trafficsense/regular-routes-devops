include_recipe "nginx"
include_recipe 'postgresql::libpq'
include_recipe 'postgresql::postgis'
include_recipe 'postgresql::server'
include_recipe 'python::pip'
include_recipe 'python::virtualenv'

cookbook_file "/etc/init/regularroutes.conf" do
  source "upstart.conf"
  mode "0644"
end

service "regularroutes" do
  action :stop
end

package 'git'
package 'language-pack-fi'
package 'libffi-dev'
package 'python-dev'

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

user 'regularroutes' do
  system true
  shell '/bin/false'
end

directory '/opt/regularroutes' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

template '/opt/regularroutes/regularroutes.cfg' do
  source 'regularroutes.cfg.erb'
  mode '0750'
  owner 'root'
  group 'regularroutes'
end

git '/opt/regularroutes/server' do
  repository 'https://github.com/aalto-trafficsense/regular-routes-server'
  revision 'master'
  action :sync
end

python_virtualenv '/opt/regularroutes/virtualenv' do
  owner 'root'
  group 'root'
  action :create
end

python_pip 'gunicorn' do
  virtualenv '/opt/regularroutes/virtualenv'
end

execute '/opt/regularroutes/virtualenv/bin/pip install -r /opt/regularroutes/server/requirements.txt' do
  cwd '/opt/regularroutes'
end

nginx_site "default" do
  enable false
end

cookbook_file "#{node.nginx.dir}/sites-available/regularroutes.conf" do
  source "nginx-site.conf"
  mode "0644"
end

nginx_site "regularroutes.conf"

cron 'curl_duplicates' do
  hour '1'
  minute '0'
  command 'curl http://localhost/api/maintenance/duplicates'
end

cron 'curl_snapping' do
  hour '2'
  minute '0'
  command 'curl http://localhost/api/maintenance/snapping'
end

service "regularroutes" do
  action [:restart, :enable]
end
