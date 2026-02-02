#
# Cookbook:: k8s-worker
# Recipe:: kubernetes
#
# Copyright:: 2025, The Authors, All Rights Reserved.

# Set logging level to reduce output
Chef::Log.level = :warn unless Chef::Config[:log_level]

# Disable swap
execute 'disable-swap' do
  command 'swapoff -a'
  only_if 'swapon -s'
end

# Remove swap entry from /etc/fstab
ruby_block 'remove swap from fstab' do
  block do
    fe = Chef::Util::FileEdit.new('/etc/fstab')
    fe.search_file_delete_line(/\sswap\s/)
    fe.write_file
  end
  only_if 'grep -q "swap" /etc/fstab'
end

# Install required packages
%w(apt-transport-https ca-certificates curl gpg).each do |pkg|
  package pkg do
    action :install
  end
end

# Create keyrings directory
directory '/etc/apt/keyrings' do
  mode '0755'
  recursive true
end

# Add Kubernetes GPG key
execute 'add-k8s-gpg-key' do
  command <<-EOH
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v#{node['kubernetes']['version']}/deb/Release.key | \
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  EOH
  creates '/etc/apt/keyrings/kubernetes-apt-keyring.gpg'
  live_stream false
end

# Add Kubernetes repository
file '/etc/apt/sources.list.d/kubernetes.list' do
  content "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v#{node['kubernetes']['version']}/deb/ /"
  mode '0644'
  notifies :update, 'apt_update[update-after-k8s-repo]', :immediately
end

# Update apt after adding repository
apt_update 'update-after-k8s-repo' do
  action :nothing
end

# Install Kubernetes components
node['kubernetes']['packages'].each do |pkg|
  package pkg do
    action :install
  end
end

# Hold packages at current version (skip if already held)
execute 'hold-k8s-packages' do
  command "apt-mark hold #{node['kubernetes']['packages'].join(' ')}"
  live_stream false
  not_if 'apt-mark showhold | grep -q kubelet'
end

# Do not start kubelet yet - it will be managed by kubeadm
service 'kubelet' do
  action :nothing
end
