#
# Cookbook:: jenkins-server
# Recipe:: default
#
# Copyright:: 2025, The Authors, All Rights Reserved.

Chef::Log.level = :info

include_recipe 'chef-vault'
include_recipe 'apt'
include_recipe 'package'
include_recipe 'nagios-client'
include_recipe 'prometheus-client'
include_recipe 'nfs-client'

begin
  app_versions = node.run_state['app_versions'] || data_bag_item('app_versions', 'default')
  node.run_state['app_versions'] = app_versions
  node.default['jenkins']['java_package'] = app_versions['jenkins']['java_package'] if app_versions.dig('jenkins', 'java_package')
  node.default['jenkins']['jenkins_version'] = app_versions['jenkins']['jenkins_version'] if app_versions.dig('jenkins', 'jenkins_version')
  node.default['jenkins']['plugins_upgrade'] = app_versions['jenkins']['plugins_upgrade'] if app_versions.dig('jenkins', 'plugins_upgrade')
  node.default['jenkins']['plugin_manager']['version'] = app_versions['jenkins']['plugin_manager_version'] if app_versions.dig('jenkins', 'plugin_manager_version')
rescue => e
  Chef::Log.warn("app_versions data bag not available: #{e.message}. Using default attributes.")
end

include_recipe 'jenkins-server::install'
include_recipe 'jenkins-server::config'
include_recipe 'jenkins-server::plugins'
include_recipe 'jenkins-server::casc'
include_recipe 'jenkins-server::service'
include_recipe 'firewall'
