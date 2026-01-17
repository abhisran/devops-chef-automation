#
# Cookbook:: k8s-worker
# Recipe:: default
#
# Copyright:: 2025, The Authors, All Rights Reserved.

# Set log level to info to reduce debug output
Chef::Log.level = :info

include_recipe 'k8s-worker::containerd'
include_recipe 'k8s-worker::kubernetes'
include_recipe 'k8s-worker::worker'
