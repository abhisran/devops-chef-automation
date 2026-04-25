#
# Cookbook:: jenkins-server
# Recipe:: casc
#
# Copyright:: 2025, The Authors, All Rights Reserved.
#
# Uses Jenkins Configuration as Code (JCasC) to idempotently register
# agent nodes, SSH credentials, and core Jenkins settings.

return unless node['jenkins']['casc']['enabled']

include_recipe 'chef-vault'

casc_path = node['jenkins']['casc']['config_path']

# Ensure SSH keys are loaded from vault (may already be in run_state from config recipe)
ruby_block 'load-jenkins-ssh-key-for-casc' do
  block do
    unless node.run_state['jenkins_ssh_private_key']
      vault = chef_vault_item(
        node['jenkins']['vault']['name'],
        node['jenkins']['vault']['item']
      )
      node.run_state['jenkins_ssh_private_key'] = vault['private_key']
      node.run_state['jenkins_k8s_token'] = vault['k8s_token']
    end
  end
end

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
      ssh_private_key: node.run_state['jenkins_ssh_private_key'] || '',
      k8s_token: node.run_state['jenkins_k8s_token'] || '',
    }
  }
  notifies :restart, 'service[jenkins]', :delayed
end

service 'jenkins' do
  action :nothing
end
