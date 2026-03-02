#
# Cookbook:: jenkins-agent
# Recipe:: default
#
# Copyright:: 2025, The Authors, All Rights Reserved.

Chef::Log.level = :info

include_recipe 'chef-vault'

begin
  app_versions = node.run_state['app_versions'] || chef_vault_item('app_versions', 'default')
  node.run_state['app_versions'] = app_versions
  node.default['jenkins']['java_package'] = app_versions['jenkins']['java_package'] if app_versions.dig('jenkins', 'java_package')
  node.default['jenkins']['agent']['kubectl']['k8s_version'] = app_versions['jenkins']['kubectl_version'] if app_versions.dig('jenkins', 'kubectl_version')
rescue => e
  Chef::Log.warn("app_versions vault not available: #{e.message}. Using default attributes.")
end

include_recipe 'jenkins-agent::install'
include_recipe 'jenkins-agent::config'
include_recipe 'jenkins-agent::docker'
include_recipe 'jenkins-agent::kubectl'
include_recipe 'jenkins-agent::service'
include_recipe 'firewall'
