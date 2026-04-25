#
# Cookbook:: jenkins-agent
# Recipe:: terraform
#
# Copyright:: 2025, The Authors, All Rights Reserved.

return unless node['jenkins']['agent']['terraform']['enabled']

# Install dependencies
package %w(curl gpg software-properties-common lsb-release)

# Create keyrings directory (shared convention with other recipes)
directory '/etc/apt/keyrings' do
  mode '0755'
  recursive true
end

# 1. Add the HashiCorp GPG key (dearmored)
execute 'add_hashicorp_key' do
  command 'curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg'
  creates '/etc/apt/keyrings/hashicorp-archive-keyring.gpg'
end

# 2. Add the official repository using the keyring
file '/etc/apt/sources.list.d/hashicorp.list' do
  content "deb [arch=amd64 signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com #{node['lsb']['codename'] || 'jammy'} main\n"
  mode '0644'
  owner 'root'
  group 'root'
  notifies :update, 'apt_update[update_for_terraform]', :immediately
end

# 3. Force an apt-get update
apt_update 'update_for_terraform' do
  action :nothing
end

# 4. Install Terraform
package 'terraform' do
  version node['jenkins']['agent']['terraform']['version'] if node['jenkins']['agent']['terraform']['version']
  action :install
end
