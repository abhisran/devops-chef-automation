#
# Cookbook:: jenkins-agent
# Recipe:: default
#
# Copyright:: 2025, The Authors, All Rights Reserved.

Chef::Log.level = :info

include_recipe 'jenkins-agent::install'
include_recipe 'jenkins-agent::config'
include_recipe 'jenkins-agent::service'
