#
# Cookbook:: jenkins-server
# Recipe:: install
#
# Copyright:: 2025, The Authors, All Rights Reserved.

package %w(fontconfig) + [node['jenkins']['java_package']]

directory '/etc/apt/keyrings' do
  mode '0755'
  recursive true
end

file '/etc/apt/keyrings/jenkins-keyring.gpg' do
  action :delete
end

execute 'add-jenkins-gpg-key' do
  command 'wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key'
  creates '/etc/apt/keyrings/jenkins-keyring.asc'
  live_stream false
end

file '/etc/apt/sources.list.d/jenkins.list' do
  content "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/\n"
  owner 'root'
  group 'root'
  mode '0644'
  notifies :update, 'apt_update[update-after-jenkins-repo]', :immediately
end

apt_update 'update-after-jenkins-repo' do
  action :nothing
end

package 'jenkins'
