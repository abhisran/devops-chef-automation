default['nagios']['version'] = '4.5.11'
default['nagios']['nrpe_version'] = '4.1.0'

default['nagios']['user'] = 'nagios'
default['nagios']['group'] = 'nagios'
default['nagios']['cmd_group'] = 'nagcmd'

default['nagios']['install_dir'] = '/usr/local/nagios'
default['nagios']['src_dir'] = '/usr/local/src'

default['nagios']['admin_user'] = 'nagiosadmin'
default['nagios']['vault']['name'] = 'nagios_credentials'
default['nagios']['vault']['item'] = 'admin_password'

# Firewall
default['firewall']['rule_groups']['nagios_server']['enabled'] = true

# Hostgroup definitions
# Note: 'linux-servers' is already defined in Nagios default config, so we use 'monitored-servers'
default['nagios']['hostgroups'] = [
  {
    'name' => 'monitored-servers',
    'alias' => 'All Monitored Servers',
  },
  {
    'name' => 'infrastructure-servers',
    'alias' => 'Infrastructure Servers (non-K8s)',
  },
  {
    'name' => 'k8s-cluster',
    'alias' => 'Kubernetes Cluster',
  },
  {
    'name' => 'k8s-masters',
    'alias' => 'Kubernetes Master Nodes',
  },
  {
    'name' => 'k8s-workers',
    'alias' => 'Kubernetes Worker Nodes',
  },
  {
    'name' => 'jenkins-servers',
    'alias' => 'Jenkins Controller Nodes',
  },
  {
    'name' => 'jenkins-agents',
    'alias' => 'Jenkins Agent Nodes',
  },
  {
    'name' => 'monitoring-servers',
    'alias' => 'Monitoring Servers',
  },
  {
    'name' => 'prometheus-servers',
    'alias' => 'Prometheus Servers',
  },
  {
    'name' => 'grafana-servers',
    'alias' => 'Grafana Servers',
  },
]

# Monitored hosts configuration
default['nagios']['monitored_hosts'] = [
  {
    'host_name' => 'master-node',
    'alias' => 'K8s Master Node',
    'address' => '192.168.1.71',
    'hostgroups' => %w(monitored-servers k8s-cluster k8s-masters),
  },
  {
    'host_name' => 'worker-node-1',
    'alias' => 'K8s Worker Node 1',
    'address' => '192.168.1.72',
    'hostgroups' => %w(monitored-servers k8s-cluster k8s-workers),
  },
  {
    'host_name' => 'worker-node-2',
    'alias' => 'K8s Worker Node 2',
    'address' => '192.168.1.73',
    'hostgroups' => %w(monitored-servers k8s-cluster k8s-workers),
  },
  {
    'host_name' => 'chef-server',
    'alias' => 'Chef Server',
    'address' => '192.168.1.70',
    'hostgroups' => %w(monitored-servers infrastructure-servers),
  },
  {
    'host_name' => 'nagios-server',
    'alias' => 'Nagios Server',
    'address' => '192.168.1.74',
    'hostgroups' => %w(monitored-servers infrastructure-servers),
  },
  {
    'host_name' => 'jenkins-server',
    'alias' => 'Jenkins Controller',
    'address' => '192.168.1.75',
    'hostgroups' => %w(monitored-servers jenkins-servers),
  },
  {
    'host_name' => 'jenkins-agent',
    'alias' => 'Jenkins Agent 1',
    'address' => '192.168.1.76',
    'hostgroups' => %w(monitored-servers jenkins-agents),
  },
  {
    'host_name' => 'prom-server',
    'alias' => 'Prometheus Server',
    'address' => '192.168.1.77',
    'hostgroups' => %w(monitored-servers monitoring-servers prometheus-servers),
  },
  {
    'host_name' => 'grafana-server',
    'alias' => 'Grafana Server',
    'address' => '192.168.1.78',
    'hostgroups' => %w(monitored-servers monitoring-servers grafana-servers),
  },
]

# Service definitions by hostgroup
# Each entry defines services that apply to a specific hostgroup
# Note: Command names must match those defined in the NRPE client config
default['nagios']['hostgroup_services'] = {
  # Common checks for all monitored servers
  'monitored-servers' => [
    { 'description' => 'Disk Usage', 'check_command' => 'check_nrpe!check_disk' },
    { 'description' => 'Memory Usage', 'check_command' => 'check_nrpe!check_mem' },
    { 'description' => 'Load Average', 'check_command' => 'check_nrpe!check_load' },
    { 'description' => 'Total Processes', 'check_command' => 'check_nrpe!check_procs' },
    { 'description' => 'Zombie Processes', 'check_command' => 'check_nrpe!check_zombie_procs' },
    { 'description' => 'SSH Service', 'check_command' => 'check_nrpe!check_ssh' },
    { 'description' => 'Logged In Users', 'check_command' => 'check_nrpe!check_users' },
  ],
  # Checks for non-K8s infrastructure servers only
  # Note: K8s nodes don't run HTTP on port 80 and require swap to be disabled
  'infrastructure-servers' => [
    { 'description' => 'HTTP Service', 'check_command' => 'check_nrpe!check_http' },
    { 'description' => 'Swap Usage', 'check_command' => 'check_nrpe!check_swap' },
  ],
  # Kubernetes cluster checks - all K8s nodes
  'k8s-cluster' => [
    # Process checks
    { 'description' => 'Kubelet Process', 'check_command' => 'check_nrpe!check_kubelet' },
    { 'description' => 'Containerd Process', 'check_command' => 'check_nrpe!check_containerd' },
    { 'description' => 'Containerd Shim', 'check_command' => 'check_nrpe!check_containerd_shim' },
    { 'description' => 'Kube Proxy Process', 'check_command' => 'check_nrpe!check_kube_proxy' },
    # Health endpoint checks
    { 'description' => 'Kubelet Health', 'check_command' => 'check_nrpe!check_kubelet_health' },
    { 'description' => 'Kube Proxy Health', 'check_command' => 'check_nrpe!check_kube_proxy_health' },
    { 'description' => 'Containerd Socket', 'check_command' => 'check_nrpe!check_containerd_socket' },
    { 'description' => 'DNS Resolution', 'check_command' => 'check_nrpe!check_dns_resolution' },
  ],
  # Kubernetes master-specific checks
  'k8s-masters' => [
    # Process checks
    { 'description' => 'API Server Process', 'check_command' => 'check_nrpe!check_kube_apiserver' },
    { 'description' => 'etcd Process', 'check_command' => 'check_nrpe!check_etcd' },
    { 'description' => 'Scheduler Process', 'check_command' => 'check_nrpe!check_kube_scheduler' },
    # Health endpoint checks
    { 'description' => 'API Server Health', 'check_command' => 'check_nrpe!check_apiserver_health' },
    { 'description' => 'etcd Health', 'check_command' => 'check_nrpe!check_etcd_health' },
    { 'description' => 'Scheduler Health', 'check_command' => 'check_nrpe!check_scheduler_health' },
    { 'description' => 'Controller Manager Health', 'check_command' => 'check_nrpe!check_controller_health' },
  ],
  # Kubernetes worker-specific checks
  # Note: Worker nodes run kube-proxy (already in k8s-cluster) but no control plane components
  'k8s-workers' => [
    # Workers don't have additional unique components beyond what's in k8s-cluster
    # This hostgroup exists for potential future worker-specific checks
  ],
  # Jenkins controller checks
  'jenkins-servers' => [
    { 'description' => 'Jenkins Process', 'check_command' => 'check_nrpe!check_jenkins_process' },
    { 'description' => 'Jenkins Web UI', 'check_command' => 'check_nrpe!check_jenkins_http' },
    { 'description' => 'Swap Usage', 'check_command' => 'check_nrpe!check_swap' },
  ],
  # Common monitoring server checks (Prometheus + Grafana)
  'monitoring-servers' => [
    { 'description' => 'Swap Usage', 'check_command' => 'check_nrpe!check_swap' },
  ],
  # Prometheus server-specific checks
  'prometheus-servers' => [
    { 'description' => 'Prometheus Process', 'check_command' => 'check_nrpe!check_prometheus_process' },
    { 'description' => 'Prometheus Health', 'check_command' => 'check_nrpe!check_prometheus_http' },
  ],
  # Grafana server-specific checks
  'grafana-servers' => [
    { 'description' => 'Grafana Process', 'check_command' => 'check_nrpe!check_grafana_process' },
    { 'description' => 'Grafana Health', 'check_command' => 'check_nrpe!check_grafana_http' },
  ],
  # Jenkins agent checks
  'jenkins-agents' => [
    { 'description' => 'Jenkins Agent User', 'check_command' => 'check_nrpe!check_jenkins_agent_user' },
    { 'description' => 'Jenkins Agent Work Dir', 'check_command' => 'check_nrpe!check_jenkins_agent_workdir' },
    { 'description' => 'Swap Usage', 'check_command' => 'check_nrpe!check_swap' },
  ],
}
