#
# Cookbook:: nfs-client
# Recipe:: mount
#
# Copyright:: 2025, The Authors, All Rights Reserved.

node['nfs']['client']['mounts'].each do |m|
  # Create local directory if it doesn't exist
  directory m['local_path'] do
    recursive true
    owner 'nobody'
    group 'nogroup'
    mode '0777'
    action :create
  end

  # Mount the NFS share
  mount m['local_path'] do
    device m['remote_path']
    fstype 'nfs'
    options m['options'] || 'rw,sync,hard,intr'
    action [:mount, :enable]
  end
end
