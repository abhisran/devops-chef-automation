include_recipe 'chef-vault'
include_recipe 'apt'
include_recipe 'package'
include_recipe 'nagios-client'
include_recipe 'prometheus-client'
include_recipe 'nfs-client'

begin
  app_versions = node.run_state['app_versions'] || data_bag_item('app_versions', 'default')
  node.run_state['app_versions'] = app_versions
  node.default['nagios']['version'] = app_versions['nagios']['version'] if app_versions.dig('nagios', 'version')
  node.default['nagios']['nrpe_version'] = app_versions['nagios']['nrpe_version'] if app_versions.dig('nagios', 'nrpe_version')
rescue => e
  Chef::Log.warn("app_versions data bag not available: #{e.message}. Using default attributes.")
end

begin
  nagios_creds = chef_vault_item(
    node['nagios']['vault']['name'],
    node['nagios']['vault']['item']
  )
  node.run_state['nagios_admin_password'] = nagios_creds['password']
rescue => e
  Chef::Log.warn("Nagios vault not available: #{e.message}. Using default password.")
  node.run_state['nagios_admin_password'] = 'nagios@123'
end

include_recipe 'nagios-server::install'
include_recipe 'nagios-server::config'
include_recipe 'nagios-server::service'
include_recipe 'firewall'
