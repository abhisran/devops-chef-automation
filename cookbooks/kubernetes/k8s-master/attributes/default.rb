# Kubernetes version
default['kubernetes']['version'] = '1.32'
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

# etcd backup
default['kubernetes']['etcd_backup']['enabled'] = true
default['kubernetes']['etcd_backup']['backup_dir'] = '/var/backups/etcd'
default['kubernetes']['etcd_backup']['script_path'] = '/usr/local/bin/etcd-backup.sh'
default['kubernetes']['etcd_backup']['etcdctl_version'] = '3.5.27'
default['kubernetes']['etcd_backup']['retention_days'] = 7
default['kubernetes']['etcd_backup']['etcd_endpoints'] = 'https://127.0.0.1:2379'
default['kubernetes']['etcd_backup']['cert_dir'] = '/etc/kubernetes/pki/etcd'
default['kubernetes']['etcd_backup']['remote']['enabled'] = true
default['kubernetes']['etcd_backup']['remote']['user'] = 'backup'
default['kubernetes']['etcd_backup']['remote']['host'] = '192.168.1.50'
default['kubernetes']['etcd_backup']['remote']['path'] = '/backups/etcd'
default['kubernetes']['etcd_backup']['remote']['retention_days'] = 7
