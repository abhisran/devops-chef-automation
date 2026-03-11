#
# Cookbook:: nfs-server
# Recipe:: config
#
# Copyright:: 2025, The Authors, All Rights Reserved.

# Create shared directories
node['nfs']['server']['exports'].each do |export|
  directory export['path'] do
    owner 'nobody'
    group 'nogroup'
    mode '0755'
    recursive true
  end
end

# Deploy /etc/nfs.conf with fixed ports
template node['nfs']['server']['config_file'] do
  source 'nfs.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[nfs-kernel-server]', :delayed
end

# Deploy /etc/default/nfs-common for statd
template node['nfs']['server']['common_config_file'] do
  source 'nfs-common.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[rpc-statd]', :delayed
end

# Pin lockd ports via sysctl
%w(nlm_tcpport nlm_udpport).each do |param|
  execute "sysctl-nfs-#{param}" do
    command "sysctl -w fs.nfs.#{param}=#{node['nfs']['server']['ports']['lockd']}"
    not_if "sysctl -n fs.nfs.#{param} | grep -q '^#{node['nfs']['server']['ports']['lockd']}$'"
  end
end

file '/etc/sysctl.d/99-nfs-lockd.conf' do
  content "fs.nfs.nlm_tcpport=#{node['nfs']['server']['ports']['lockd']}\nfs.nfs.nlm_udpport=#{node['nfs']['server']['ports']['lockd']}\n"
  owner 'root'
  group 'root'
  mode '0644'
end

# Lockd modprobe configuration (extra layer for boot-time/reload)
file node['nfs']['server']['lockd_modprobe_file'] do
  content "options lockd nlm_tcpport=#{node['nfs']['server']['ports']['lockd']} nlm_udpport=#{node['nfs']['server']['ports']['lockd']}\n"
  owner 'root'
  group 'root'
  mode '0644'
end

# Deploy /etc/exports
template node['nfs']['server']['exports_file'] do
  source 'exports.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    exports: node['nfs']['server']['exports']
  )
  notifies :run, 'execute[exportfs-reload]', :delayed
end

execute 'exportfs-reload' do
  command 'exportfs -ra'
  action :nothing
end
