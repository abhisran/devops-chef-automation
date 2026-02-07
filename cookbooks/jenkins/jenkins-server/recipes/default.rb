#
# Cookbook:: jenkins-server
# Recipe:: default
#
# Copyright:: 2025, The Authors, All Rights Reserved.

Chef::Log.level = :info

include_recipe 'jenkins-server::install'
include_recipe 'jenkins-server::config'
include_recipe 'jenkins-server::service'
include_recipe 'jenkins-server::plugins'
include_recipe 'jenkins-server::casc'
