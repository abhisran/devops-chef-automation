#
# Cookbook:: nfs-server
# Recipe:: default
#
# Copyright:: 2025, The Authors, All Rights Reserved.

include_recipe 'apt'
include_recipe 'package'
include_recipe 'nfs-server::install'
include_recipe 'nfs-server::config'
include_recipe 'nfs-server::service'
include_recipe 'firewall'
include_recipe 'nagios-client'
include_recipe 'prometheus-client'
include_recipe 'nfs-client'
