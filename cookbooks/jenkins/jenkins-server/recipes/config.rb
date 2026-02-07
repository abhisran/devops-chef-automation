#
# Cookbook:: jenkins-server
# Recipe:: config
#
# Copyright:: 2025, The Authors, All Rights Reserved.

template '/etc/default/jenkins' do
  source 'jenkins_defaults.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    jenkins_home: node['jenkins']['home'],
    http_port: node['jenkins']['port'],
    java_args: node['jenkins']['java_args'],
    jenkins_user: node['jenkins']['user'],
    casc_config_path: node['jenkins']['casc']['config_path']
  )
  notifies :restart, 'service[jenkins]', :delayed
end

# Systemd override for modern Jenkins packages that use systemd directly
directory '/etc/systemd/system/jenkins.service.d' do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
end

template '/etc/systemd/system/jenkins.service.d/override.conf' do
  source 'jenkins_systemd_override.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    jenkins_home: node['jenkins']['home'],
    http_port: node['jenkins']['port'],
    java_args: node['jenkins']['java_args'],
    jenkins_user: node['jenkins']['user'],
    casc_config_path: node['jenkins']['casc']['config_path']
  )
  notifies :run, 'execute[systemctl-daemon-reload]', :immediately
  notifies :restart, 'service[jenkins]', :delayed
end

execute 'systemctl-daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
  live_stream false
end

directory "#{node['jenkins']['home']}/.ssh" do
  owner node['jenkins']['user']
  group node['jenkins']['group']
  mode '0700'
end

# Generate SSH keypair so the Jenkins server can SSH into agents
execute 'generate-jenkins-ssh-key' do
  command "ssh-keygen -t rsa -b 4096 -f #{node['jenkins']['home']}/.ssh/id_rsa -N '' -C 'jenkins@#{node['hostname']}'"
  user node['jenkins']['user']
  creates "#{node['jenkins']['home']}/.ssh/id_rsa"
  live_stream false
end
