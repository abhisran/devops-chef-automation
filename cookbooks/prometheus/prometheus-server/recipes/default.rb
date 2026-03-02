include_recipe 'chef-vault'

begin
  app_versions = node.run_state['app_versions'] || chef_vault_item('app_versions', 'default')
  node.run_state['app_versions'] = app_versions
  node.default['prometheus']['server']['version'] = app_versions['prometheus']['server_version'] if app_versions.dig('prometheus', 'server_version')
rescue => e
  Chef::Log.warn("app_versions vault not available: #{e.message}. Using default attributes.")
end

include_recipe 'prometheus-server::install'
include_recipe 'prometheus-server::config'
include_recipe 'prometheus-server::service'
include_recipe 'firewall'
