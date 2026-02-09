#
# Cookbook:: jenkins-agent
# Recipe:: config
#
# Copyright:: 2025, The Authors, All Rights Reserved.

include_recipe 'chef-vault'

ssh_dir = "#{node['jenkins']['agent']['home']}/.ssh"

directory ssh_dir do
  owner node['jenkins']['agent']['user']
  group node['jenkins']['agent']['group']
  mode '0700'
end

# Load SSH public key from Chef Vault
ruby_block 'load-jenkins-ssh-public-key-from-vault' do
  block do
    vault = chef_vault_item(
      node['jenkins']['vault']['name'],
      node['jenkins']['vault']['item']
    )
    node.run_state['jenkins_agent_ssh_public_key'] = vault['public_key']
  end
end

file "#{ssh_dir}/authorized_keys" do
  content lazy { "#{node.run_state['jenkins_agent_ssh_public_key']}\n" }
  owner node['jenkins']['agent']['user']
  group node['jenkins']['agent']['group']
  mode '0600'
  only_if { !node.run_state['jenkins_agent_ssh_public_key'].to_s.strip.empty? }
end

directory node['jenkins']['agent']['work_dir'] do
  owner node['jenkins']['agent']['user']
  group node['jenkins']['agent']['group']
  mode '0755'
  recursive true
end
