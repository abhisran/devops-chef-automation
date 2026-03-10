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

# Prometheus server-specific check commands
default['nagios']['nrpe']['prometheus_commands'] = {
  'check_prometheus_process' => '-C prometheus -c 1:',
}

# Prometheus server health check commands
default['nagios']['nrpe']['prometheus_health_commands'] = {
  'check_prometheus_http' => '/usr/lib/nagios/plugins/check_http -H localhost -p 9090 -u /-/healthy -e 200',
}

# Grafana server-specific check commands
default['nagios']['nrpe']['grafana_commands'] = {
  'check_grafana_process' => '-a grafana -c 1:',
}

# Grafana server health check commands
default['nagios']['nrpe']['grafana_health_commands'] = {
  'check_grafana_http' => '/usr/lib/nagios/plugins/check_http -H localhost -p 3000 -u /api/health -e 200',
}

# Chef client-specific check commands
# These monitor the health of the chef-client systemd timer and run status
default['nagios']['nrpe']['chef_client_commands'] = {
  'check_chef_client_timer' => '/bin/bash -c \'if systemctl is-active --quiet chef-client.timer; then echo "OK: chef-client.timer is active"; exit 0; else echo "CRITICAL: chef-client.timer is not active"; exit 2; fi\'',
  'check_chef_client_run' => '/bin/bash -c \'LOG=/var/log/chef/client.log; if [ ! -f "$LOG" ]; then echo "CRITICAL: Chef client log not found"; exit 2; fi; AGE=$(( $(date +%s) - $(stat -c %Y "$LOG") )); if [ $AGE -gt 3600 ]; then echo "CRITICAL: Chef client last ran ${AGE}s ago"; exit 2; elif [ $AGE -gt 2700 ]; then echo "WARNING: Chef client last ran ${AGE}s ago"; exit 1; else echo "OK: Chef client last ran ${AGE}s ago"; exit 0; fi\'',
  'check_chef_client_status' => '/bin/bash -c \'STATUS=$(systemctl show chef-client.service --property=Result --value 2>/dev/null); if [ "$STATUS" = "success" ]; then echo "OK: Last chef-client run succeeded"; exit 0; elif [ -z "$STATUS" ]; then echo "WARNING: chef-client.service status unknown"; exit 1; else echo "CRITICAL: Last chef-client run failed (Result=$STATUS)"; exit 2; fi\'',
}

# NFS server-specific check commands
default['nagios']['nrpe']['nfs_commands'] = {
  'check_nfs_process' => '-C nfsd -c 1:',
}

# NFS server health check commands
default['nagios']['nrpe']['nfs_health_commands'] = {
  'check_nfs_exports' => '/bin/bash -c \'EXPORTS=$(exportfs -s 2>/dev/null | wc -l); if [ $EXPORTS -gt 0 ]; then echo "OK: $EXPORTS NFS export(s) active"; exit 0; else echo "CRITICAL: No NFS exports found"; exit 2; fi\'',
}

# Additional custom commands can be added here or via role/environment override
default['nagios']['nrpe']['custom_commands'] = {}
