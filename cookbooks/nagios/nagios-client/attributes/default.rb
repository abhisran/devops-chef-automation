# NRPE Configuration
default['nagios']['nrpe']['user'] = 'nagios'
default['nagios']['nrpe']['group'] = 'nagios'

# Nagios Server IP - clients accept NRPE connections from this server
default['nagios']['server']['ip'] = '192.168.1.55'

# Allowed hosts - Nagios server(s) that can connect to this NRPE daemon
default['nagios']['nrpe']['allowed_hosts'] = ['127.0.0.1', '::1', node['nagios']['server']['ip']]

# NRPE daemon settings
default['nagios']['nrpe']['server_port'] = 5666
default['nagios']['nrpe']['dont_blame_nrpe'] = 0
default['nagios']['nrpe']['allow_bash_command_substitution'] = 0
default['nagios']['nrpe']['debug'] = 0
default['nagios']['nrpe']['command_timeout'] = 60
default['nagios']['nrpe']['connection_timeout'] = 300

# Plugin directory - varies by platform, set in recipe
default['nagios']['nrpe']['plugin_dir'] = '/usr/lib/nagios/plugins'

# NRPE check commands
# These must match the command names used in the Nagios server's service definitions
default['nagios']['nrpe']['commands'] = {
  'check_disk' => '-w 20% -c 10% -p /',
  'check_load' => '-w 15,10,5 -c 30,25,20',
  'check_swap' => '-w 20% -c 10%',
  'check_procs' => '-w 250 -c 400',
  'check_zombie_procs' => '-w 5 -c 10 -s Z',
  'check_ssh' => '-H localhost',
  'check_http' => '-H localhost',
  'check_users' => '-w 5 -c 10'
}

# Additional custom commands can be added here or via role/environment override
default['nagios']['nrpe']['custom_commands'] = {}
