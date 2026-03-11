#
# Cookbook:: jenkins-agent
# Recipe:: azure_cli
#
# Copyright:: 2025, The Authors, All Rights Reserved.

return unless node['jenkins']['agent']['azure_cli']['enabled']

# Install dependencies
package %w(ca-certificates curl apt-transport-https lsb-release gnupg)

# Create keyrings directory
directory '/etc/apt/keyrings' do
  recursive true
end

# Add Microsoft GPG key
remote_file '/etc/apt/keyrings/microsoft.gpg' do
  source 'https://packages.microsoft.com/keys/microsoft.asc'
  mode '0644'
end

# Add Azure CLI repository
apt_repository 'azure-cli' do
  uri 'https://packages.microsoft.com/repos/azure-cli/'
  key 'https://packages.microsoft.com/keys/microsoft.asc'
  distribution node['lsb']['codename']
  components ['main']
  action :add
end

# Install Azure CLI
package 'azure-cli' do
  action :install
end
