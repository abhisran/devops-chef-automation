#
# Cookbook:: k8s-master
# Recipe:: master
#
# Copyright:: 2025, The Authors, All Rights Reserved.

# Pull required images first (skip if cluster already initialized)
execute 'kubeadm config images pull' do
  live_stream false
  not_if { ::File.exist?('/etc/kubernetes/admin.conf') }
end

# Initialize Kubernetes master (skip if already initialized)
execute 'kubeadm init' do
  live_stream false
  not_if { ::File.exist?('/etc/kubernetes/admin.conf') }
end

# Configure kubectl for the root user
directory '/root/.kube' do
  owner 'root'
  group 'root'
  mode '0755'
end

execute 'copy-kube-config' do
  command 'cp /etc/kubernetes/admin.conf /root/.kube/config'
  live_stream false
  only_if { ::File.exist?('/etc/kubernetes/admin.conf') }
  not_if { ::File.exist?('/root/.kube/config') }
end

# Install Weave network plugin (kubectl apply is idempotent)
# Retries handle the case where the API server isn't ready yet
# (e.g. when chef-client runs via systemd timer shortly after a reboot)
execute 'install-network-plugin' do
  command "kubectl apply -f #{node['kubernetes']['network_plugin']['url']}"
  live_stream false
  retries 3
  retry_delay 10
  only_if 'kubectl get --raw /readyz 2>/dev/null'
  only_if { ::File.exist?('/root/.kube/config') }
end
