#
# Cookbook:: k8s-master
# Recipe:: containerd
#
# Copyright:: 2025, The Authors, All Rights Reserved.

# Set logging level to reduce output
Chef::Log.level = :warn unless Chef::Config[:log_level]

# Create keyrings directory
directory '/etc/apt/keyrings' do
  mode '0755'
  recursive true
end

# Add Docker's official GPG key
execute 'add-docker-gpg-key' do
  command <<-EOH
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
  EOH
  creates '/etc/apt/keyrings/docker.gpg'
end

# Add Docker repository
file '/etc/apt/sources.list.d/docker.list' do
  content 'deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable'
  notifies :run, 'apt_update[update_apt_cache]', :immediately
end

apt_update 'update_apt_cache' do
  action :update
end

# Install containerd
package 'containerd.io'

# Configure kernel modules
file '/etc/modules-load.d/k8s.conf' do
  content "overlay\nbr_netfilter\n"
end

# Load required kernel modules immediately
%w(overlay br_netfilter).each do |mod|
  execute "load-module-#{mod}" do
    command "modprobe #{mod}"
    not_if "lsmod | grep -q '^#{mod}'"
  end
end

node['kubernetes']['sysctl_params'].each do |key, value|
  execute "set-sysctl-#{key}" do
    command "sysctl -w #{key}=#{value}"
    not_if "sysctl -n #{key} | grep -q '^#{value}$'"
  end
end

# Configure containerd
directory '/etc/containerd' do
  mode '0755'
end

containerd_config '/etc/containerd/config.toml' do
  systemd_cgroup true
  notifies :restart, 'service[containerd]'
end

service 'containerd' do
  action [:enable, :start]
end

# Install CNI plugins
remote_file "#{Chef::Config[:file_cache_path]}/cni-plugins.tgz" do
  source "https://github.com/containernetworking/plugins/releases/download/v#{node['kubernetes']['cni_version']}/cni-plugins-linux-amd64-v#{node['kubernetes']['cni_version']}.tgz"
  mode '0644'
  action :create
end

directory node['kubernetes']['cni']['bin_dir'] do
  recursive true
  mode '0755'
end

execute 'extract-cni-plugins' do
  command "tar xzf #{Chef::Config[:file_cache_path]}/cni-plugins.tgz -C #{node['kubernetes']['cni']['bin_dir']}"
  creates "#{node['kubernetes']['cni']['bin_dir']}/bridge"
end
