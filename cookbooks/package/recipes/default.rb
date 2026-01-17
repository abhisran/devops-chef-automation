#
# Cookbook:: package
# Recipe:: default
#
# Copyright:: 2025, The Authors, All Rights Reserved.

# Update package repositories
apt_update 'update' do
  action :update
end

# Essential packages for VM setup
%w(
  curl
  git
  neovim
  net-tools
  wget
  conntrack
).each do |pkg|
  package pkg do
    action :install
  end
end
