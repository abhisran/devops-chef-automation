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

# Direct download for critical trilead-api plugin to ensure Jenkins can always boot
# This bypasses the plugin manager's update center metadata check which is currently failing.
remote_file "#{plugin_dir}/trilead-api.jpi" do
  source 'https://updates.jenkins.io/latest/trilead-api.hpi'
  owner node['jenkins']['user']
  group node['jenkins']['group']
  mode '0644'
  not_if { ::File.exist?("#{plugin_dir}/trilead-api.jpi") || ::File.exist?("#{plugin_dir}/trilead-api.hpi") }
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
  # Filter out problematic plugins like ssh-api
  installed_plugins.reject! { |p| %w(ssh-api).include?(p) }
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

# Explicitly trigger the upgrade check even if plugins.txt hasn't changed.
ruby_block 'trigger-jenkins-plugin-upgrade' do
  block do
    plugin_dir_path = "#{node['jenkins']['home']}/plugins"

    state_before = Dir.glob("#{plugin_dir_path}/*.{jpi,hpi}").sort.map { |f|
      [File.basename(f), File.size(f), File.mtime(f).to_i]
    }

    cmd = Mixlib::ShellOut.new(
      "java -jar #{node['jenkins']['plugin_manager']['jar_path']} " \
      "--war #{node['jenkins']['war_path']} " \
      "--plugin-download-directory #{plugin_dir_path} " \
      "--plugin-file #{node['jenkins']['home']}/plugins.txt --verbose",
      timeout: 900,
      live_stream: STDOUT
    )
    cmd.run_command
    
    if cmd.error?
      Chef::Log.error("Jenkins Plugin Manager failed to reconcile updates (likely Update Center timeout). Proceeding anyway.")
    end

    FileUtils.chown_R(node['jenkins']['user'], node['jenkins']['group'], plugin_dir_path)

    state_after = Dir.glob("#{plugin_dir_path}/*.{jpi,hpi}").sort.map { |f|
      [File.basename(f), File.size(f), File.mtime(f).to_i]
    }

    if state_before != state_after
      Chef::Log.info('Plugins were updated - restarting Jenkins')
      resources('service[jenkins]').run_action(:restart)
    else
      Chef::Log.info('No plugin updates found - Jenkins restart not needed')
    end
  end
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

service 'jenkins' do
  action :nothing
end
