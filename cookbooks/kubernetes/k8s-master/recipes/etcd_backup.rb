#
# Cookbook:: k8s-master
# Recipe:: etcd_backup
#
# Copyright:: 2025, The Authors, All Rights Reserved.

return unless node['kubernetes']['etcd_backup']['enabled']

etcdctl_version = node['kubernetes']['etcd_backup']['etcdctl_version']

# Install etcdctl (not included on the host in kubeadm clusters)
remote_file "#{Chef::Config[:file_cache_path]}/etcd-v#{etcdctl_version}-linux-amd64.tar.gz" do
  source "https://github.com/etcd-io/etcd/releases/download/v#{etcdctl_version}/etcd-v#{etcdctl_version}-linux-amd64.tar.gz"
  mode '0644'
  action :create
  notifies :run, 'execute[install-etcdctl]', :immediately
end

execute 'install-etcdctl' do
  command <<-EOH
    tar xzf #{Chef::Config[:file_cache_path]}/etcd-v#{etcdctl_version}-linux-amd64.tar.gz \
      -C /usr/local/bin --strip-components=1 \
      etcd-v#{etcdctl_version}-linux-amd64/etcdctl
  EOH
  action :nothing
end

directory node['kubernetes']['etcd_backup']['backup_dir'] do
  owner 'root'
  group 'root'
  mode '0750'
  recursive true
end

template node['kubernetes']['etcd_backup']['script_path'] do
  source 'etcd_backup.sh.erb'
  owner 'root'
  group 'root'
  mode '0750'
  variables(
    backup_dir: node['kubernetes']['etcd_backup']['backup_dir'],
    retention_days: node['kubernetes']['etcd_backup']['retention_days'],
    etcd_endpoints: node['kubernetes']['etcd_backup']['etcd_endpoints'],
    cert_dir: node['kubernetes']['etcd_backup']['cert_dir'],
    remote_enabled: node['kubernetes']['etcd_backup']['remote']['enabled'],
    remote_user: node['kubernetes']['etcd_backup']['remote']['user'],
    remote_host: node['kubernetes']['etcd_backup']['remote']['host'],
    remote_path: node['kubernetes']['etcd_backup']['remote']['path'],
    remote_retention_days: node['kubernetes']['etcd_backup']['remote']['retention_days']
  )
end
