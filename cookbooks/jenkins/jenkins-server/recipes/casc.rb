#
# Cookbook:: jenkins-server
# Recipe:: casc
#
# Copyright:: 2025, The Authors, All Rights Reserved.
#
# Uses Jenkins Configuration as Code (JCasC) to idempotently register
# agent nodes, SSH credentials, and core Jenkins settings.

return unless node['jenkins']['casc']['enabled']

casc_path = node['jenkins']['casc']['config_path']
ssh_key_path = "#{node['jenkins']['home']}/.ssh/id_rsa"

template casc_path do
  source 'jenkins_casc.yaml.erb'
  owner node['jenkins']['user']
  group node['jenkins']['group']
  mode '0600'
  sensitive true
  variables lazy {
    {
      agents: node['jenkins']['agents'],
      jenkins_url: node['jenkins']['casc']['jenkins_url'],
      controller_executors: node['jenkins']['casc']['controller_executors'],
      ssh_private_key: ::File.exist?(ssh_key_path) ? ::File.read(ssh_key_path) : '',
    }
  }
  notifies :restart, 'service[jenkins]', :delayed
end
