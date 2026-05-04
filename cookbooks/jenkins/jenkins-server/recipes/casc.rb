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

# Ensure credentials are loaded from vault (may already be partially in run_state from config recipe)
ruby_block 'load-jenkins-vault-items-for-casc' do
  block do
    # We load if EITHER is missing to ensure full state for the template
    if node.run_state['jenkins_ssh_private_key'].nil? || node.run_state['jenkins_k8s_token'].nil?
      vault = chef_vault_item(
        node['jenkins']['vault']['name'],
        node['jenkins']['vault']['item']
      )
      node.run_state['jenkins_ssh_private_key'] ||= vault['private_key']
      node.run_state['jenkins_k8s_token'] = vault['k8s_token']
      node.run_state['github_private_key'] = vault['github_private_key']
      node.run_state['dockerhub_username'] = vault['dockerhub_username']
      node.run_state['dockerhub_password'] = vault['dockerhub_password']
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
      github_private_key: node.run_state['github_private_key'] || '',
      dockerhub_username: node.run_state['dockerhub_username'] || '',
      dockerhub_password: node.run_state['dockerhub_password'] || '',
    }
  }
  notifies :restart, 'service[jenkins]', :delayed
end
