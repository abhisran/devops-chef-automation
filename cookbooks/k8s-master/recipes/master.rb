#
# Cookbook:: k8s-master
# Recipe:: master
#
# Copyright:: 2025, The Authors, All Rights Reserved.

# Pull required images first
execute 'kubeadm config images pull' do
  live_stream false
end

# Initialize Kubernetes master
execute 'kubeadm init' do
  live_stream false
end

# Configure kubectl for the root user
directory '/root/.kube' do
  owner 'root'
  group 'root'
  mode '0755'
end

execute 'cp -i /etc/kubernetes/admin.conf /root/.kube/config' do
  live_stream false
end

# Install Weave network plugin
execute "kubectl apply -f #{node['kubernetes']['network_plugin']['url']}" do
  live_stream false
end
