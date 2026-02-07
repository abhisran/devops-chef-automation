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

execute 'download-jenkins-plugin-manager' do
  command "curl -fsSL -o #{pm_jar} #{pm_url}"
  creates pm_jar
  live_stream false
end

file "#{node['jenkins']['home']}/plugins.txt" do
  content node['jenkins']['plugins'].sort.join("\n") + "\n"
  owner node['jenkins']['user']
  group node['jenkins']['group']
  mode '0644'
  notifies :run, 'execute[install-jenkins-plugins]', :immediately
end

execute 'install-jenkins-plugins' do
  command "java -jar #{pm_jar} --war #{node['jenkins']['war_path']} --plugin-download-directory #{plugin_dir} --plugin-file #{node['jenkins']['home']}/plugins.txt --verbose"
  action :nothing
  live_stream false
  notifies :run, 'execute[fix-plugin-permissions]', :immediately
  notifies :restart, 'service[jenkins]', :delayed
end

execute 'fix-plugin-permissions' do
  command "chown -R #{node['jenkins']['user']}:#{node['jenkins']['group']} #{plugin_dir}"
  action :nothing
  live_stream false
end
