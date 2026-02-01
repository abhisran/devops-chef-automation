# Create nagios user and group
group node['nagios']['nrpe']['group']

user node['nagios']['nrpe']['user'] do
  group node['nagios']['nrpe']['group']
  shell '/usr/sbin/nologin'
  system true
  manage_home false
end

# Platform-specific package installation
case node['platform_family']
when 'debian'
  package %w(
    nagios-nrpe-server
    monitoring-plugins
    monitoring-plugins-basic
    monitoring-plugins-common
    monitoring-plugins-standard
  )

  # Set plugin directory for Debian
  node.default['nagios']['nrpe']['plugin_dir'] = '/usr/lib/nagios/plugins'

when 'rhel', 'fedora'
  # Enable EPEL repository for NRPE packages
  package 'epel-release' do
    only_if { platform_family?('rhel') }
  end

  package %w(
    nrpe
    nagios-plugins-all
  )

  # Set plugin directory for RHEL
  node.default['nagios']['nrpe']['plugin_dir'] = '/usr/lib64/nagios/plugins'

else
  raise "Unsupported platform family: #{node['platform_family']}. This cookbook supports debian and rhel families."
end

# Create NRPE config directory if it doesn't exist
directory '/etc/nagios' do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
end
