#
# Cookbook:: nfs-client
# Recipe:: default
#
# Copyright:: 2025, The Authors, All Rights Reserved.

include_recipe 'apt'
include_recipe 'package'
include_recipe 'nfs-client::install'
include_recipe 'nfs-client::mount'
include_recipe 'nagios-client'
include_recipe 'prometheus-client'
