# NRPE config file location (same across platforms when using packages)
nrpe_config_file = '/etc/nagios/nrpe.cfg'

# Determine NRPE local config file for custom commands
nrpe_local_config = if platform_family?('rhel', 'fedora')
                      '/etc/nrpe.d/chef_commands.cfg'
                    else
                      '/etc/nagios/nrpe_local.cfg'
                    end

# Create nrpe.d directory for RHEL if needed
if platform_family?('rhel', 'fedora')
  directory '/etc/nrpe.d' do
    owner 'root'
    group 'root'
    mode '0755'
  end
end

# Deploy main NRPE configuration file
template nrpe_config_file do
  source 'nrpe.cfg.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    nrpe_user: node['nagios']['nrpe']['user'],
    nrpe_group: node['nagios']['nrpe']['group'],
    allowed_hosts: node['nagios']['nrpe']['allowed_hosts'].join(','),
    server_port: node['nagios']['nrpe']['server_port'],
    dont_blame_nrpe: node['nagios']['nrpe']['dont_blame_nrpe'],
    allow_bash_command_substitution: node['nagios']['nrpe']['allow_bash_command_substitution'],
    debug: node['nagios']['nrpe']['debug'],
    command_timeout: node['nagios']['nrpe']['command_timeout'],
    connection_timeout: node['nagios']['nrpe']['connection_timeout'],
    plugin_dir: node['nagios']['nrpe']['plugin_dir'],
    commands: node['nagios']['nrpe']['commands'],
    custom_commands: node['nagios']['nrpe']['custom_commands'],
    include_dir: platform_family?('rhel', 'fedora') ? '/etc/nrpe.d' : nil,
    include_local: platform_family?('debian') ? '/etc/nagios/nrpe_local.cfg' : nil
  )
  notifies :restart, 'service[nrpe]', :delayed
end

# Deploy local config file for custom commands (Debian)
if platform_family?('debian')
  template nrpe_local_config do
    source 'nrpe_local.cfg.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      custom_commands: node['nagios']['nrpe']['custom_commands'],
      plugin_dir: node['nagios']['nrpe']['plugin_dir']
    )
    notifies :restart, 'service[nrpe]', :delayed
  end
end
