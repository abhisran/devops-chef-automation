#
# Cookbook:: jenkins-agent
# Recipe:: install
#
# Copyright:: 2025, The Authors, All Rights Reserved.

apt_update 'periodic' do
  frequency 86400
  action :periodic
end

package %w(fontconfig) + [node['jenkins']['java_package']]

group node['jenkins']['agent']['group'] do
  system true
end

user node['jenkins']['agent']['user'] do
  group node['jenkins']['agent']['group']
  home node['jenkins']['agent']['home']
  shell '/bin/bash'
  system true
  manage_home true
end

node['jenkins']['agent']['build_packages'].each do |pkg|
  package pkg
end
