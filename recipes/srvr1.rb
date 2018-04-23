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

# A basic working solution is here: https://medium.com/@pierangelo1982/a-basic-nginx-cookbook-for-chef-ba95d801dbf3

# include_recipe 'nginx'

package 'nginx' do
  action :install
end

cookbook_file "#{node['nginx']['dir']}/sites-available/regularroutes.conf" do
  source "nginx-site.conf"
  mode "0644"
end

service 'nginx' do
  action [ :enable, :start ]
end


python_runtime '3' do
  provider :system
  options package_name: 'python3'
  pip_version false
  setuptools_version false
  wheel_version false
end

package 'libffi-dev'
package 'python-dev'

template '/opt/regularroutes/regularroutes.cfg' do
  source 'regularroutes.cfg.erb'
  mode '0750'
  owner 'root'
  group 'lerero'
end

git '/opt/regularroutes/server' do
  repository node[:regularroutes][:server_git_url]
  revision node[:regularroutes][:server_branch]
  action :checkout
  action :sync
end


directory '/opt/regularroutes/virtualenv' do
  owner 'root'
  group 'root'
  action :create
end

python_virtualenv '/opt/regularroutes/virtualenv' do
  python '3'
  pip_version false
  setuptools_version false
  wheel_version false
end

# Currently disabled, since poise-python crashes due to a faulty rexexp thinking that pip version > 10 are older than v. 6
# Resurrect, when postgresql_lwrp (or another postgresql-cookbook) learns to use newer poise-python than 1.6.0
# Also allow pip, setuptools and wheel updates to virtualenv above, when that happens.

# python_package 'gunicorn' do
#   virtualenv '/opt/regularroutes/virtualenv'
# end

# pip_requirements '/opt/regularroutes/server/requirements.txt' do
#   virtualenv '/opt/regularroutes/virtualenv'
# end

bash 'do_python' do
  cwd '/opt/regularroutes/'
  code <<-EOH
    /opt/regularroutes/virtualenv/bin/pip install setuptools
    /opt/regularroutes/virtualenv/bin/pip install gunicorn
    /opt/regularroutes/virtualenv/bin/pip install -r /opt/regularroutes/server/requirements.txt
  EOH
end
