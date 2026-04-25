#
# Cookbook:: jenkins-server
# Recipe:: config
#
# Copyright:: 2025, The Authors, All Rights Reserved.

template '/etc/default/jenkins' do
  source 'jenkins_defaults.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    jenkins_home: node['jenkins']['home'],
    http_port: node['jenkins']['port'],
    java_args: node['jenkins']['java_args'],
    jenkins_user: node['jenkins']['user'],
    casc_config_path: node['jenkins']['casc']['config_path']
  )
  notifies :restart, 'service[jenkins]', :delayed
end

# Systemd override for modern Jenkins packages that use systemd directly
directory '/etc/systemd/system/jenkins.service.d' do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
end

template '/etc/systemd/system/jenkins.service.d/override.conf' do
  source 'jenkins_systemd_override.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    jenkins_home: node['jenkins']['home'],
    http_port: node['jenkins']['port'],
    java_args: node['jenkins']['java_args'],
    jenkins_user: node['jenkins']['user'],
    casc_config_path: node['jenkins']['casc']['config_path']
  )
  notifies :run, 'execute[systemctl-daemon-reload]', :immediately
  notifies :restart, 'service[jenkins]', :delayed
end

execute 'systemctl-daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
  live_stream false
end

directory "#{node['jenkins']['home']}/.ssh" do
  owner node['jenkins']['user']
  group node['jenkins']['group']
  mode '0700'
end

# Load SSH key pair from Chef Vault
ruby_block 'load-jenkins-ssh-keys-from-vault' do
  block do
    vault = chef_vault_item(
      node['jenkins']['vault']['name'],
      node['jenkins']['vault']['item']
    )
    node.run_state['jenkins_ssh_private_key'] = vault['private_key']
    node.run_state['jenkins_ssh_public_key'] = vault['public_key']
  end
end

# Deploy private key from vault (PEM format required by Jenkins trilead-api)
file "#{node['jenkins']['home']}/.ssh/id_rsa" do
  content lazy { node.run_state['jenkins_ssh_private_key'] }
  owner node['jenkins']['user']
  group node['jenkins']['group']
  mode '0600'
  sensitive true
  not_if { node.run_state['jenkins_ssh_private_key'].to_s.strip.empty? }
end

file "#{node['jenkins']['home']}/.ssh/id_rsa.pub" do
  content lazy { "#{node.run_state['jenkins_ssh_public_key']}\n" }
  owner node['jenkins']['user']
  group node['jenkins']['group']
  mode '0644'
  not_if { node.run_state['jenkins_ssh_public_key'].to_s.strip.empty? }
end
