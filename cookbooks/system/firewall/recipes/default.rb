#
# Cookbook:: firewall
# Recipe:: default
#
# Copyright:: 2025, The Authors, All Rights Reserved.

return unless node['firewall']['enabled']

include_recipe 'firewall::install'
include_recipe 'firewall::config'
include_recipe 'firewall::service'
