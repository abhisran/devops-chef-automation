#
# Cookbook:: nfs-server
# Recipe:: service
#
# Copyright:: 2025, The Authors, All Rights Reserved.

service 'nfs-kernel-server' do
  supports restart: true, status: true, reload: true
  action [:enable, :start]
end

service 'rpc-statd' do
  supports restart: true, status: true
  action [:enable, :start]
end
