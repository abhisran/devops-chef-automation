#
# Cookbook:: jenkins-server
# Recipe:: plugins
#
# Copyright:: 2025, The Authors, All Rights Reserved.

pm_version = node['jenkins']['plugin_manager']['version']
pm_jar = node['jenkins']['plugin_manager']['jar_path']
pm_url = "https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/#{pm_version}/jenkins-plugin-manager-#{pm_version}.jar"
plugin_dir = "#{node['jenkins']['home']}/plugins"

directory plugin_dir do
  owner node['jenkins']['user']
  group node['jenkins']['group']
  mode '0755'
end

# SURGICAL RECOVERY: Download only critical plugins manually to ensure boot
critical_plugins = %w(
  trilead-api
  ssh-slaves
  ssh-credentials
  credentials
  structs
  workflow-step-api
  scm-api
  script-security
  display-url-api
  junit
  apache-httpcomponents-client-4-api
)

critical_plugins.each do |plugin|
  remote_file "#{plugin_dir}/#{plugin}.jpi" do
    source "https://updates.jenkins.io/latest/#{plugin}.hpi"
    owner node['jenkins']['user']
    group node['jenkins']['group']
    mode '0644'
    action :create
  end
end

execute 'download-jenkins-plugin-manager' do
  command "curl -fsSL -o #{pm_jar} #{pm_url}"
  not_if { ::File.exist?(pm_jar) }
  live_stream false
end

# Prepare the full plugin list for future reconciliation
plugin_list = node['jenkins']['plugins'].uniq

file "#{node['jenkins']['home']}/plugins.txt" do
  content plugin_list.sort.join("\n") + "\n"
  owner node['jenkins']['user']
  group node['jenkins']['group']
  mode '0644'
end

# Fix permissions
execute 'fix-plugin-permissions' do
  command "chown -R #{node['jenkins']['user']}:#{node['jenkins']['group']} #{plugin_dir}"
  action :run
end

service 'jenkins' do
  action :nothing
end
