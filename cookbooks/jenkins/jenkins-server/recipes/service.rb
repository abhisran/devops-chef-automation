#
# Cookbook:: jenkins-server
# Recipe:: service
#
# Copyright:: 2025, The Authors, All Rights Reserved.

service 'jenkins' do
  supports restart: true, status: true, reload: true
  action [:enable, :start]
end
