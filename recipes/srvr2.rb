# Start everything

service "regularroutes-api" do
  action [:restart, :enable]
end
sleep(3)

service "regularroutes-site" do
  action [:restart, :enable]
end
sleep(3)

# MJR: Commenting out 3.6.2016 as the dev interface must not be available on production servers
# service "regularroutes-dev" do
#   action [:restart, :enable]
# end
# sleep(3)

service "regularroutes-scheduler" do
  action [:restart, :enable]
end
