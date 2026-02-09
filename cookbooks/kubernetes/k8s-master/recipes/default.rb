#
# Cookbook:: k8s-master
# Recipe:: default
#
# Copyright:: 2025, The Authors, All Rights Reserved.

# Set log level to info to reduce debug output
Chef::Log.level = :info

include_recipe 'k8s-master::containerd'
include_recipe 'k8s-master::kubernetes'
include_recipe 'k8s-master::master'
include_recipe 'k8s-master::rbac'
