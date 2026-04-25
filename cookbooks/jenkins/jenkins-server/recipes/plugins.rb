#
# Cookbook:: jenkins-server
# Recipe:: plugins
#
# Copyright:: 2025, The Authors, All Rights Reserved.
#
# Installs Jenkins plugins using the official jenkins-plugin-manager CLI tool.
# Plugin list changes trigger a reinstall + Jenkins restart. To force an upgrade
# of already-installed plugins, set node['jenkins']['plugins_upgrade'] = true.

pm_version  = node['jenkins']['plugin_manager']['version']
pm_jar      = node['jenkins']['plugin_manager']['jar_path']
pm_url      = "https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/#{pm_version}/jenkins-plugin-manager-#{pm_version}.jar"
plugin_dir  = "#{node['jenkins']['home']}/plugins"
plugins_txt = "#{node['jenkins']['home']}/plugins.txt"
jenkins_user  = node['jenkins']['user']
jenkins_group = node['jenkins']['group']
upgrade_plugins = node['jenkins']['plugins_upgrade']

directory plugin_dir do
  owner jenkins_user
  group jenkins_group
  mode '0755'
end

remote_file pm_jar do
  source pm_url
  owner 'root'
  group 'root'
  mode '0644'
  action :create_if_missing
end

file plugins_txt do
  content node['jenkins']['plugins'].uniq.sort.join("\n") + "\n"
  owner jenkins_user
  group jenkins_group
  mode '0644'
  notifies :run, 'execute[install-jenkins-plugins]', :delayed
end

# Installs plugins from plugins.txt and resolves transitive dependencies.
#
# We always pass --latest true because our plugins.txt lists plugin names
# without version pins. With --latest false, plugin-manager installs the
# *minimum required* dep versions, which breaks when a top-level plugin has
# been upgraded to a version that needs newer deps (results in "Plugin is
# missing: ..." errors at Jenkins startup).
#
# Triggered on plugins.txt changes. Set node['jenkins']['plugins_upgrade'] to
# true to force a re-run on every converge (pulls newer top-level versions).
execute 'install-jenkins-plugins' do
  command "java -jar #{pm_jar} " \
          "--war #{node['jenkins']['war_path']} " \
          "--plugin-file #{plugins_txt} " \
          "--plugin-download-directory #{plugin_dir} " \
          '--latest true'
  user jenkins_user
  group jenkins_group
  environment 'HOME' => node['jenkins']['home']
  live_stream false
  action upgrade_plugins ? :run : :nothing
  notifies :restart, 'service[jenkins]', :delayed
end

# Idempotent ownership fix: only runs if a file in plugin_dir isn't owned by jenkins.
execute 'fix-plugin-permissions' do
  command "chown -R #{jenkins_user}:#{jenkins_group} #{plugin_dir}"
  only_if "find #{plugin_dir} \\( -not -user #{jenkins_user} -o -not -group #{jenkins_group} \\) -print -quit 2>/dev/null | grep -q ."
end
