begin
  app_versions = node.run_state['app_versions'] || data_bag_item('app_versions', 'default')
  node.run_state['app_versions'] = app_versions
  node.default['prometheus']['node_exporter']['version'] = app_versions['prometheus']['node_exporter_version'] if app_versions.dig('prometheus', 'node_exporter_version')
rescue => e
  Chef::Log.warn("app_versions data bag not available: #{e.message}. Using default attributes.")
end

include_recipe 'prometheus-client::install'
include_recipe 'prometheus-client::config'
include_recipe 'prometheus-client::service'
include_recipe 'firewall'
