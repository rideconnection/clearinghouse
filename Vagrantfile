# This is a simple 64-bit Ubuntu 12.04 LTS box that has Chef
# pre-installed. Use for testing your recipes. Do not use for production
# deployments.

Vagrant::Config.run do |config|
  config.vm.define "ch_web" do |node_config|
    node_config.vm.box = 'hashicorp/precise64'
    node_config.vm.network :hostonly, "33.33.33.10"
    # node_config.vm.host_name = "web-01.ch.rideconnection.org"
    # node_config.vm.share_folder "v-cookbooks", "/cookbooks", "."
  end
  
  config.vm.define "ch_db" do |node_config|
    node_config.vm.box = 'hashicorp/precise64'
    node_config.vm.network :hostonly, "33.33.33.11"
    # node_config.vm.host_name = "db-01.ch.rideconnection.org"
    # node_config.vm.share_folder "v-cookbooks", "/cookbooks", "."
  end
end
