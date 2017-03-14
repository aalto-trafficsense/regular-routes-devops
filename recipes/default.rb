cookbook_file "/etc/init/regularroutes-api.conf" do
  source "upstart-api.conf"
  mode "0644"
end

cookbook_file "/etc/init/regularroutes-site.conf" do
  source "upstart-site.conf"
  mode "0644"
end

cookbook_file "/etc/init/regularroutes-dev.conf" do
  source "upstart-dev.conf"
  mode "0644"
end

cookbook_file "/etc/init/regularroutes-scheduler.conf" do
  source "upstart-scheduler.conf"
  mode "0644"
end

cookbook_file "/etc/systemd/system/regularroutes-api.service" do
  source "systemd-api.service"
  mode "0644"
end

cookbook_file "/etc/systemd/system/regularroutes-site.service" do
  source "systemd-site.service"
  mode "0644"
end

cookbook_file "/etc/systemd/system/regularroutes-dev.service" do
  source "systemd-dev.service"
  mode "0644"
end

cookbook_file "/etc/systemd/system/regularroutes-scheduler.service" do
  source "systemd-scheduler.service"
  mode "0644"
end

service "regularroutes-api" do
  action :stop
end

service "regularroutes-site" do
  action :stop
end

# MJR: Commenting out 3.6.2016 as the dev interface must not be available on production servers, so it should not be running in the first place
# service "regularroutes-dev" do
#   action :stop
# end

service "regularroutes-scheduler" do
  action :stop
end

include_recipe 'regularroutes::_base'
include_recipe 'nginx'
include_recipe 'python::pip'
include_recipe 'python::virtualenv'

package 'libffi-dev'
package 'python-dev'

template '/opt/regularroutes/regularroutes.cfg' do
  source 'regularroutes.cfg.erb'
  mode '0750'
  owner 'root'
  group 'lerero'
end

git '/opt/regularroutes/server' do
  repository 'https://github.com/aalto-trafficsense/regular-routes-server'
  revision node[:regularroutes][:server_branch]
  action :checkout
  action :sync
end

# MJR commented out 3.6.2016: Current html picks the favicon from static/icon
# execute 'cp favicon.ico /var/www/html/' do
#   cwd '/opt/regularroutes/server/static/icon'
# end

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
  command 'curl -s http://127.0.0.1/api/maintenance/duplicates'
  user 'lerero'
end

cron 'curl_snapping' do
  hour '2'
  minute '0'
  command 'curl -s http://127.0.0.1/api/maintenance/snapping'
  user 'lerero'
end

service "regularroutes-api" do
  action [:restart, :enable]
end

service "regularroutes-site" do
  action [:restart, :enable]
end

# MJR: Commenting out 3.6.2016 as the dev interface must not be available on production servers
# service "regularroutes-dev" do
#   action [:restart, :enable]
# end

service "regularroutes-scheduler" do
  action [:restart, :enable]
end
