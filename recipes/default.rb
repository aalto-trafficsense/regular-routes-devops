include_recipe 'regularroutes::srvr1'
# Give postgresql time to start before starting the services
sleep(10)
include_recipe 'regularroutes::srvr2'
