default['nagios']['version'] = '4.5.11'
default['nagios']['nrpe_version'] = '4.1.0'

default['nagios']['user'] = 'nagios'
default['nagios']['group'] = 'nagios'
default['nagios']['cmd_group'] = 'nagcmd'

default['nagios']['install_dir'] = '/usr/local/nagios'
default['nagios']['src_dir'] = '/usr/local/src'

default['nagios']['admin_user'] = 'nagiosadmin'

# Hostgroup definitions
default['nagios']['hostgroups'] = [
  {
    'name' => 'linux-servers',
    'alias' => 'All Linux Servers'
  },
  {
    'name' => 'k8s-cluster',
    'alias' => 'Kubernetes Cluster'
  },
  {
    'name' => 'k8s-masters',
    'alias' => 'Kubernetes Master Nodes'
  },
  {
    'name' => 'k8s-workers',
    'alias' => 'Kubernetes Worker Nodes'
  }
]

# Monitored hosts configuration
default['nagios']['monitored_hosts'] = [
  {
    'host_name' => 'master-node',
    'alias' => 'K8s Master Node',
    'address' => '192.168.1.51',
    'hostgroups' => ['linux-servers', 'k8s-cluster', 'k8s-masters']
  },
  {
    'host_name' => 'worker-node-1',
    'alias' => 'K8s Worker Node 1',
    'address' => '192.168.1.52',
    'hostgroups' => ['linux-servers', 'k8s-cluster', 'k8s-workers']
  },
  {
    'host_name' => 'worker-node-2',
    'alias' => 'K8s Worker Node 2',
    'address' => '192.168.1.53',
    'hostgroups' => ['linux-servers', 'k8s-cluster', 'k8s-workers']
  },
  {
    'host_name' => 'chef-server',
    'alias' => 'Chef Server',
    'address' => '192.168.1.54',
    'hostgroups' => ['linux-servers']
  }
]

# Service definitions by hostgroup
# Each entry defines services that apply to a specific hostgroup
default['nagios']['hostgroup_services'] = {
  'linux-servers' => [
    { 'description' => 'Disk Usage', 'check_command' => 'check_nrpe!check_disk' },
    { 'description' => 'Load Average', 'check_command' => 'check_nrpe!check_load' },
    { 'description' => 'Memory Usage', 'check_command' => 'check_nrpe!check_mem' },
    { 'description' => 'Swap Usage', 'check_command' => 'check_nrpe!check_swap' },
    { 'description' => 'Total Processes', 'check_command' => 'check_nrpe!check_procs' },
    { 'description' => 'Zombie Processes', 'check_command' => 'check_nrpe!check_zombie_procs' },
    { 'description' => 'SSH Service', 'check_command' => 'check_nrpe!check_ssh' },
    { 'description' => 'HTTP Service', 'check_command' => 'check_nrpe!check_http' },
    { 'description' => 'CPU Usage', 'check_command' => 'check_nrpe!check_cpu' }
  ]
}
