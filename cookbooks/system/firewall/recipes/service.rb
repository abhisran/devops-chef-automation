#
# Cookbook:: firewall
# Recipe:: service
#
# Copyright:: 2025, The Authors, All Rights Reserved.

execute 'ufw-enable' do
  command 'ufw --force enable'
  not_if "ufw status | grep -q 'Status: active'"
end
