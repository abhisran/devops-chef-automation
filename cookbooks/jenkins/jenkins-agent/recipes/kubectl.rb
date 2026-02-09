#
# Cookbook:: jenkins-agent
# Recipe:: kubectl
#
# Copyright:: 2025, The Authors, All Rights Reserved.

return unless node['jenkins']['agent']['kubectl']['enabled']

include_recipe 'chef-vault'

k8s_version = node['jenkins']['agent']['kubectl']['k8s_version']

# Install prerequisites
package %w(apt-transport-https ca-certificates curl gnupg)

# Create keyrings directory
directory '/etc/apt/keyrings' do
  mode '0755'
  recursive true
end

# Add Kubernetes GPG key
execute 'add-k8s-gpg-key-for-kubectl' do
  command "curl -fsSL https://pkgs.k8s.io/core:/stable:/v#{k8s_version}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg"
  creates '/etc/apt/keyrings/kubernetes-apt-keyring.gpg'
  live_stream false
end

# Add Kubernetes repository
file '/etc/apt/sources.list.d/kubernetes.list' do
  content "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v#{k8s_version}/deb/ /\n"
  mode '0644'
  notifies :update, 'apt_update[update-after-k8s-repo-for-kubectl]', :immediately
end

apt_update 'update-after-k8s-repo-for-kubectl' do
  action :nothing
end

# Install kubectl
package 'kubectl'

# Create .kube directory for jenkins user
directory "#{node['jenkins']['agent']['home']}/.kube" do
  owner node['jenkins']['agent']['user']
  group node['jenkins']['agent']['group']
  mode '0700'
end

# Load kubeconfig from Chef Vault (graceful if vault not created yet)
ruby_block 'load-jenkins-kubeconfig-from-vault' do
  block do
    begin
      vault = chef_vault_item(
        node['jenkins']['vault']['name'],
        node['jenkins']['vault']['kubeconfig_item']
      )
      node.run_state['jenkins_kubeconfig'] = vault['kubeconfig']
    rescue => e
      Chef::Log.warn("Kubeconfig vault not available yet: #{e.message}. Skipping kubeconfig deployment.")
    end
  end
end

# Deploy kubeconfig
file "#{node['jenkins']['agent']['home']}/.kube/config" do
  content lazy { node.run_state['jenkins_kubeconfig'] }
  owner node['jenkins']['agent']['user']
  group node['jenkins']['agent']['group']
  mode '0600'
  sensitive true
  only_if { !node.run_state['jenkins_kubeconfig'].to_s.strip.empty? }
end
