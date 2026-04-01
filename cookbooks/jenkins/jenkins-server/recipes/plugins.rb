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
  not_if { ::File.exist?(pm_jar) }
  live_stream false
end

# Determine the plugin list. If 'plugins_upgrade' is true, we discover all existing plugins
# on disk to ensure we reconcile and update the entire suite.
plugin_list = node['jenkins']['plugins'].dup

if node['jenkins']['plugins_upgrade'] && ::Dir.exist?(plugin_dir)
  # Find all currently installed plugin files (.jpi or .hpi)
  installed_plugins = Dir.glob("#{plugin_dir}/*.{jpi,hpi}").map { |f| File.basename(f, '.*') }
  plugin_list = (plugin_list + installed_plugins).uniq
  Chef::Log.info("Plugins Upgrade enabled: Discovered #{installed_plugins.length} installed plugins to reconcile.")
end

file "#{node['jenkins']['home']}/plugins.txt" do
  content plugin_list.sort.join("\n") + "\n"
  owner node['jenkins']['user']
  group node['jenkins']['group']
  mode '0644'
  notifies :run, 'execute[install-jenkins-plugins]', :immediately
end

# Explicitly trigger the upgrade check even if plugins.txt hasn't changed
log 'trigger-jenkins-plugin-upgrade' do
  message 'Forcing full Jenkins plugin upgrade check...'
  level :info
  notifies :run, 'execute[install-jenkins-plugins]', :immediately
  only_if { node['jenkins']['plugins_upgrade'] }
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
