# UFW global settings
default['firewall']['enabled'] = true
default['firewall']['default_policy_incoming'] = 'deny'
default['firewall']['default_policy_outgoing'] = 'allow'
default['firewall']['default_policy_routed'] = 'deny'
default['firewall']['logging'] = 'low'

# Rule groups — enable per-node via role/environment attributes
# Each group has an 'enabled' flag and a 'rules' hash of named rules.
# Each rule: port (String), protocol (tcp/udp), action (allow/deny),
#            optional source (IP/CIDR), comment (String)

# Common rules (all nodes)
default['firewall']['rule_groups']['common']['enabled'] = true
default['firewall']['rule_groups']['common']['rules'] = {
  'ssh' => {
    'port' => '22',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'SSH access',
  },
}

# Nagios NRPE client (all monitored nodes)
default['firewall']['rule_groups']['nagios_client']['enabled'] = true
default['firewall']['rule_groups']['nagios_client']['rules'] = {
  'nrpe' => {
    'port' => '5666',
    'protocol' => 'tcp',
    'action' => 'allow',
    'source' => '192.168.1.74',
    'comment' => 'NRPE from Nagios server',
  },
}

# Prometheus Node Exporter (all monitored nodes)
default['firewall']['rule_groups']['prometheus_client']['enabled'] = true
default['firewall']['rule_groups']['prometheus_client']['rules'] = {
  'node_exporter' => {
    'port' => '9100',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'Prometheus Node Exporter',
  },
}

# Kubernetes master node
default['firewall']['rule_groups']['k8s_master']['enabled'] = false
default['firewall']['rule_groups']['k8s_master']['rules'] = {
  'apiserver' => {
    'port' => '6443',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'K8s API Server',
  },
  'etcd_client' => {
    'port' => '2379:2380',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'etcd client communication',
  },
  'etcd_health' => {
    'port' => '2381',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'etcd health endpoint',
  },
  'kubelet_api' => {
    'port' => '10250',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'Kubelet API',
  },
  'kube_scheduler' => {
    'port' => '10259',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'kube-scheduler HTTPS',
  },
  'kube_controller' => {
    'port' => '10257',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'kube-controller-manager HTTPS',
  },
  'kube_proxy_health' => {
    'port' => '10256',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'kube-proxy healthz',
  },
  'kubelet_health' => {
    'port' => '10248',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'kubelet healthz',
  },
  'kube_state_metrics' => {
    'port' => '30080',
    'protocol' => 'tcp',
    'action' => 'allow',
    'source' => '192.168.1.77',
    'comment' => 'kube-state-metrics NodePort (Prometheus only)',
  },
  'weave_tcp' => {
    'port' => '6783',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'Weave Net TCP',
  },
  'weave_udp' => {
    'port' => '6783',
    'protocol' => 'udp',
    'action' => 'allow',
    'comment' => 'Weave Net UDP',
  },
  'weave_fastdp' => {
    'port' => '6784',
    'protocol' => 'udp',
    'action' => 'allow',
    'comment' => 'Weave Net FastDP',
  },
}

# Kubernetes worker node
default['firewall']['rule_groups']['k8s_worker']['enabled'] = false
default['firewall']['rule_groups']['k8s_worker']['rules'] = {
  'kubelet_api' => {
    'port' => '10250',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'Kubelet API',
  },
  'kube_proxy_health' => {
    'port' => '10256',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'kube-proxy healthz',
  },
  'kubelet_health' => {
    'port' => '10248',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'kubelet healthz',
  },
  'nodeports' => {
    'port' => '30000:32767',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'K8s NodePort range',
  },
  'weave_tcp' => {
    'port' => '6783',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'Weave Net TCP',
  },
  'weave_udp' => {
    'port' => '6783',
    'protocol' => 'udp',
    'action' => 'allow',
    'comment' => 'Weave Net UDP',
  },
  'weave_fastdp' => {
    'port' => '6784',
    'protocol' => 'udp',
    'action' => 'allow',
    'comment' => 'Weave Net FastDP',
  },
}

# Jenkins server
default['firewall']['rule_groups']['jenkins_server']['enabled'] = false
default['firewall']['rule_groups']['jenkins_server']['rules'] = {
  'jenkins_http' => {
    'port' => '8080',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'Jenkins HTTP',
  },
}

# Nagios server
default['firewall']['rule_groups']['nagios_server']['enabled'] = false
default['firewall']['rule_groups']['nagios_server']['rules'] = {
  'http' => {
    'port' => '80',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'Apache HTTP (Nagios UI)',
  },
}

# Prometheus server
default['firewall']['rule_groups']['prometheus_server']['enabled'] = false
default['firewall']['rule_groups']['prometheus_server']['rules'] = {
  'prometheus' => {
    'port' => '9090',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'Prometheus UI/API',
  },
}

# Grafana server
default['firewall']['rule_groups']['grafana_server']['enabled'] = false
default['firewall']['rule_groups']['grafana_server']['rules'] = {
  'grafana' => {
    'port' => '3000',
    'protocol' => 'tcp',
    'action' => 'allow',
    'comment' => 'Grafana UI',
  },
}
