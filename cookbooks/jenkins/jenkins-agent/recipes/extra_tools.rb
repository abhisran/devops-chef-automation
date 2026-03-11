#
# Cookbook:: jenkins-agent
# Recipe:: extra_tools
#
# Copyright:: 2025, The Authors, All Rights Reserved.

# jq
package 'jq' if node['jenkins']['agent']['jq']['enabled']

# Ansible
package 'ansible' if node['jenkins']['agent']['ansible']['enabled']

# Maven
package 'maven'

# Utilities
package %w(zip unzip tar bzip2)

# Python and pip
if node['jenkins']['agent']['python']['enabled']
  package %w(python3 python3-pip python3-venv)
end

# Helm
if node['jenkins']['agent']['helm']['enabled']
  execute 'install_helm' do
    command 'curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'
    creates '/usr/local/bin/helm'
  end
end
