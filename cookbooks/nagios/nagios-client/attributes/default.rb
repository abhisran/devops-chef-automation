# NRPE Configuration
default['nagios']['nrpe']['user'] = 'nagios'
default['nagios']['nrpe']['group'] = 'nagios'

# Nagios Server IP - clients accept NRPE connections from this server
default['nagios']['server']['ip'] = '192.168.1.74'

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
  'check_users' => '-w 5 -c 10',

}

# Kubernetes-specific check commands
# These are used for monitoring K8s cluster nodes
default['nagios']['nrpe']['k8s_commands'] = {
  # Common K8s node services (run on all K8s nodes)
  'check_kubelet' => '-C kubelet -c 1:',
  'check_containerd' => '-C containerd -c 1:',
  'check_containerd_shim' => '-C containerd-shim -c 1:',
  'check_kube_proxy' => '-C kube-proxy -c 1:',
  # K8s master components
  'check_kube_apiserver' => '-C kube-apiserver -c 1:',
  'check_etcd' => '-C etcd -c 1:',
  'check_kube_scheduler' => '-C kube-scheduler -c 1:',
  # Note: kube-controller-manager uses -a (argument matching) as the process
  # may appear with a different command name in some K8s deployments
  'check_kube_controller' => '-a kube-controller -c 1:',
}

# K8s health check commands (these use custom scripts or different plugins)
default['nagios']['nrpe']['k8s_health_commands'] = {
  # Check kubelet health endpoint
  'check_kubelet_health' => '/usr/lib/nagios/plugins/check_http -H localhost -p 10248 -u /healthz -e 200',
  # Check if node is ready via kubelet
  'check_node_ready' => '/usr/lib/nagios/plugins/check_http -H localhost -p 10248 -u /healthz -e 200',
  # Check kube-proxy health (if metrics enabled)
  'check_kube_proxy_health' => '/usr/lib/nagios/plugins/check_http -H localhost -p 10256 -u /healthz -e 200',
  # Check CoreDNS (runs as pods, check via DNS resolution)
  'check_dns_resolution' => '/usr/lib/nagios/plugins/check_dns -H kubernetes.default.svc.cluster.local -s 10.96.0.10',
  # Check container runtime socket
  'check_containerd_socket' => '/bin/bash -c \'test -S /run/containerd/containerd.sock && echo "OK: containerd socket exists" || (echo "CRITICAL: containerd socket missing"; exit 2)\'',
}

# K8s master-specific health commands
default['nagios']['nrpe']['k8s_master_health_commands'] = {
  # Check API server health endpoint
  'check_apiserver_health' => '/usr/lib/nagios/plugins/check_http -H localhost -p 6443 -S -u /healthz -e 200',
  # Check etcd health
  'check_etcd_health' => '/usr/lib/nagios/plugins/check_http -H localhost -p 2381 -u /health -e 200',
  # Check scheduler health
  'check_scheduler_health' => '/usr/lib/nagios/plugins/check_http -H localhost -p 10259 -S -u /healthz -e 200',
  # Check controller-manager health
  'check_controller_health' => '/usr/lib/nagios/plugins/check_http -H localhost -p 10257 -S -u /healthz -e 200',
}

# Jenkins-specific check commands
# These are used for monitoring Jenkins server nodes
default['nagios']['nrpe']['jenkins_commands'] = {
  'check_jenkins_process' => '-C java -a jenkins -c 1:',
}

# Jenkins health check commands (server only)
default['nagios']['nrpe']['jenkins_health_commands'] = {
  'check_jenkins_http' => '/usr/lib/nagios/plugins/check_http -H localhost -p 8080 -u /login -e 200',
}

# Jenkins agent-specific check commands
default['nagios']['nrpe']['jenkins_agent_commands'] = {
  'check_jenkins_agent_user' => '/bin/bash -c \'id jenkins >/dev/null 2>&1 && echo "OK: jenkins user exists" || (echo "CRITICAL: jenkins user missing"; exit 2)\'',
  'check_jenkins_agent_workdir' => '/bin/bash -c \'test -d /var/lib/jenkins/agent && echo "OK: agent work directory exists" || (echo "CRITICAL: agent work directory missing"; exit 2)\'',
}

# Additional custom commands can be added here or via role/environment override
default['nagios']['nrpe']['custom_commands'] = {}
