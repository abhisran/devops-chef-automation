# Kubernetes version
default['kubernetes']['version'] = '1.33'
default['kubernetes']['packages'] = %w(kubelet kubeadm kubectl)
default['kubernetes']['cni_version'] = '1.4.0'

# Container runtime
default['kubernetes']['container_runtime'] = {
  'name' => 'containerd',
  'version' => 'latest',
  'config_path' => '/etc/containerd/config.toml',
}

# System settings
default['kubernetes']['sysctl_params'] = {
  'net.ipv4.ip_forward' => 1,
  'net.bridge.bridge-nf-call-iptables' => 1,
  'net.bridge.bridge-nf-call-ip6tables' => 1,
}

# CNI settings
default['kubernetes']['cni'] = {
  'bin_dir' => '/opt/cni/bin',
  'conf_dir' => '/etc/cni/net.d',
}

# Network plugin
default['kubernetes']['network_plugin'] = {
  'name' => 'weave',
  'url' => 'https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml',
}

# Jenkins CI/CD RBAC
default['kubernetes']['rbac']['jenkins']['enabled'] = true
default['kubernetes']['rbac']['jenkins']['service_account'] = 'jenkins-deployer'
default['kubernetes']['rbac']['jenkins']['namespace'] = 'ci-cd'
default['kubernetes']['rbac']['jenkins']['deploy_namespaces'] = %w(default staging production)


# Prometheus monitoring RBAC
default['kubernetes']['rbac']['prometheus']['enabled'] = true
default['kubernetes']['rbac']['prometheus']['service_account'] = 'prometheus'
default['kubernetes']['rbac']['prometheus']['namespace'] = 'monitoring'
default['kubernetes']['rbac']['prometheus']['token_output_path'] = '/etc/kubernetes/prometheus-token.txt'

# Monitoring — patch static pod manifests to expose metrics on 0.0.0.0
default['kubernetes']['monitoring']['patch_manifests'] = true

# kube-state-metrics
default['kubernetes']['kube_state_metrics']['enabled'] = true
default['kubernetes']['kube_state_metrics']['version'] = '2.13.0'
default['kubernetes']['kube_state_metrics']['namespace'] = 'kube-system'
default['kubernetes']['kube_state_metrics']['nodeport'] = 30080
default['kubernetes']['kube_state_metrics']['image'] = 'registry.k8s.io/kube-state-metrics/kube-state-metrics'

# Firewall
default['firewall']['rule_groups']['k8s_master']['enabled'] = true

