#
# Cookbook:: jenkins-agent
# Recipe:: config
#
# Copyright:: 2025, The Authors, All Rights Reserved.

ssh_dir = "#{node['jenkins']['agent']['home']}/.ssh"

directory ssh_dir do
  owner node['jenkins']['agent']['user']
  group node['jenkins']['agent']['group']
  mode '0700'
end

file "#{ssh_dir}/authorized_keys" do
  content "#{node['jenkins']['agent']['ssh_public_key']}\n"
  owner node['jenkins']['agent']['user']
  group node['jenkins']['agent']['group']
  mode '0600'
  only_if { !node['jenkins']['agent']['ssh_public_key'].to_s.empty? }
end

directory node['jenkins']['agent']['work_dir'] do
  owner node['jenkins']['agent']['user']
  group node['jenkins']['agent']['group']
  mode '0755'
  recursive true
end
