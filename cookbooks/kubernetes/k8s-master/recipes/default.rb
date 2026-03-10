#
# Cookbook:: k8s-master
# Recipe:: default
#
# Copyright:: 2025, The Authors, All Rights Reserved.

# Set log level to info to reduce debug output
Chef::Log.level = :info

include_recipe 'chef-vault'
include_recipe 'apt'
include_recipe 'package'
include_recipe 'nagios-client'
include_recipe 'prometheus-client'

begin
  app_versions = node.run_state['app_versions'] || data_bag_item('app_versions', 'default')
  node.run_state['app_versions'] = app_versions
  node.default['kubernetes']['version'] = app_versions['kubernetes']['version'] if app_versions.dig('kubernetes', 'version')
  node.default['kubernetes']['cni_version'] = app_versions['kubernetes']['cni_version'] if app_versions.dig('kubernetes', 'cni_version')
rescue => e
  Chef::Log.warn("app_versions data bag not available: #{e.message}. Using default attributes.")
end

include_recipe 'k8s-master::containerd'
include_recipe 'k8s-master::kubernetes'
include_recipe 'k8s-master::master'
include_recipe 'k8s-master::rbac'
include_recipe 'k8s-master::monitoring'
include_recipe 'k8s-master::kube_state_metrics'
include_recipe 'firewall'
