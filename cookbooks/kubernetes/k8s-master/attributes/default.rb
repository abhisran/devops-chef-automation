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
default['kubernetes']['rbac']['jenkins']['deploy_namespaces'] = %w(staging production)

# Firewall
default['firewall']['rule_groups']['k8s_master']['enabled'] = true

