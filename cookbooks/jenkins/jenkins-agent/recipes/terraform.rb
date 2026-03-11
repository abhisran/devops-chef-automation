#
# Cookbook:: jenkins-agent
# Recipe:: terraform
#
# Copyright:: 2025, The Authors, All Rights Reserved.

return unless node['jenkins']['agent']['terraform']['enabled']

# Install dependencies
package %w(curl gpg software-properties-common lsb-release)

# 1. Add the HashiCorp GPG key (dearmored)
execute 'add_hashicorp_key' do
  command 'curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg'
  creates '/usr/share/keyrings/hashicorp-archive-keyring.gpg'
end

# 2. Add the Official Repository using the keyring
# We use a file resource here to ensure the "signed-by" option is exactly as required
file '/etc/apt/sources.list.d/hashicorp.list' do
  content "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com #{node['lsb']['codename'] || 'jammy'} main\n"
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
