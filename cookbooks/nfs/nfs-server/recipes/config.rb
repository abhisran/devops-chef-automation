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
