include_recipe 'apt'
include_recipe 'package'
include_recipe 'nagios-client'
include_recipe 'prometheus-client'
include_recipe 'nfs-client'

begin
  app_versions = node.run_state['app_versions'] || data_bag_item('app_versions', 'default')
  node.run_state['app_versions'] = app_versions
  node.default['grafana']['server']['version'] = app_versions['grafana']['version'] if app_versions.dig('grafana', 'version')
rescue => e
  Chef::Log.warn("app_versions data bag not available: #{e.message}. Using default attributes.")
end

include_recipe 'grafana-server::install'
include_recipe 'grafana-server::config'
include_recipe 'grafana-server::service'
include_recipe 'firewall'
