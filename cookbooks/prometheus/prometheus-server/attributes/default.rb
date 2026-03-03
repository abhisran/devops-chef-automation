# Prometheus version and installation
default['prometheus']['server']['version'] = '2.53.3'
default['prometheus']['server']['install_dir'] = '/opt/prometheus'
default['prometheus']['server']['config_dir'] = '/etc/prometheus'
default['prometheus']['server']['data_dir'] = '/var/lib/prometheus'
default['prometheus']['server']['user'] = 'prometheus'
default['prometheus']['server']['group'] = 'prometheus'

# Network settings
default['prometheus']['server']['port'] = 9090
default['prometheus']['server']['listen_address'] = '0.0.0.0'

# Storage settings
default['prometheus']['server']['retention_time'] = '15d'
default['prometheus']['server']['retention_size'] = '0' # 0 = unlimited

# Global scrape settings
default['prometheus']['server']['scrape_interval'] = '15s'
default['prometheus']['server']['evaluation_interval'] = '15s'
default['prometheus']['server']['scrape_timeout'] = '10s'

# Scrape targets
# Each entry: { 'job_name' => '...', 'targets' => ['host:port', ...], 'metrics_path' => '/metrics', 'scheme' => 'http' }
# Optional keys: 'tls_config' => { 'insecure_skip_verify' => true }, 'bearer_token_file' => '/path/to/token'
default['prometheus']['server']['scrape_configs'] = [
  {
    'job_name' => 'prometheus',
    'targets' => ['localhost:9090'],
    'metrics_path' => '/metrics',
    'scheme' => 'http',
  },
  {
    'job_name' => 'node_exporter',
    'targets' => [
      '192.168.1.70:9100',
      '192.168.1.71:9100',
      '192.168.1.72:9100',
      '192.168.1.73:9100',
      '192.168.1.74:9100',
      '192.168.1.75:9100',
      '192.168.1.76:9100',
      '192.168.1.77:9100',
      '192.168.1.78:9100',
    ],
    'metrics_path' => '/metrics',
    'scheme' => 'http',
  },
  # Kubernetes API Server metrics (HTTPS, requires bearer token)
  {
    'job_name' => 'kube_apiserver',
    'targets' => ['192.168.1.71:6443'],
    'metrics_path' => '/metrics',
    'scheme' => 'https',
    'tls_config' => { 'insecure_skip_verify' => true },
    'bearer_token_file' => '/etc/prometheus/k8s_token',
  },
  # Kubelet metrics (HTTPS on all K8s nodes, requires bearer token)
  {
    'job_name' => 'kubelet',
    'targets' => [
      '192.168.1.71:10250',
      '192.168.1.72:10250',
      '192.168.1.73:10250',
    ],
    'metrics_path' => '/metrics',
    'scheme' => 'https',
    'tls_config' => { 'insecure_skip_verify' => true },
    'bearer_token_file' => '/etc/prometheus/k8s_token',
  },
  # cAdvisor metrics via kubelet (per-container CPU/memory/restarts)
  {
    'job_name' => 'cadvisor',
    'targets' => [
      '192.168.1.71:10250',
      '192.168.1.72:10250',
      '192.168.1.73:10250',
    ],
    'metrics_path' => '/metrics/cadvisor',
    'scheme' => 'https',
    'tls_config' => { 'insecure_skip_verify' => true },
    'bearer_token_file' => '/etc/prometheus/k8s_token',
  },
  # etcd metrics (HTTP on metrics port)
  # Note: kubeadm defaults etcd --listen-metrics-urls to http://127.0.0.1:2381.
  # To scrape externally, add --listen-metrics-urls=http://0.0.0.0:2381 to the
  # etcd static pod manifest (/etc/kubernetes/manifests/etcd.yaml).
  {
    'job_name' => 'etcd',
    'targets' => ['192.168.1.71:2381'],
    'metrics_path' => '/metrics',
    'scheme' => 'http',
  },
  # kube-scheduler metrics (HTTPS, requires bearer token)
  # Note: kubeadm defaults --bind-address to 127.0.0.1. To scrape externally,
  # set --bind-address=0.0.0.0 in /etc/kubernetes/manifests/kube-scheduler.yaml.
  {
    'job_name' => 'kube_scheduler',
    'targets' => ['192.168.1.71:10259'],
    'metrics_path' => '/metrics',
    'scheme' => 'https',
    'tls_config' => { 'insecure_skip_verify' => true },
    'bearer_token_file' => '/etc/prometheus/k8s_token',
  },
  # kube-controller-manager metrics (HTTPS, requires bearer token)
  # Note: kubeadm defaults --bind-address to 127.0.0.1. To scrape externally,
  # set --bind-address=0.0.0.0 in /etc/kubernetes/manifests/kube-controller-manager.yaml.
  {
    'job_name' => 'kube_controller_manager',
    'targets' => ['192.168.1.71:10257'],
    'metrics_path' => '/metrics',
    'scheme' => 'https',
    'tls_config' => { 'insecure_skip_verify' => true },
    'bearer_token_file' => '/etc/prometheus/k8s_token',
  },
  # Jenkins metrics (requires the 'prometheus' Jenkins plugin)
  {
    'job_name' => 'jenkins',
    'targets' => ['192.168.1.75:8080'],
    'metrics_path' => '/prometheus',
    'scheme' => 'http',
  },
  # Grafana built-in metrics
  {
    'job_name' => 'grafana',
    'targets' => ['192.168.1.78:3000'],
    'metrics_path' => '/metrics',
    'scheme' => 'http',
  },
]

# Firewall
default['firewall']['rule_groups']['prometheus_server']['enabled'] = true

# Alertmanager integration (disabled by default — enable when Alertmanager is deployed)
default['prometheus']['server']['alertmanager']['enabled'] = false
default['prometheus']['server']['alertmanager']['targets'] = ['localhost:9093']

# Alert rules
default['prometheus']['server']['alert_rules']['enabled'] = true
default['prometheus']['server']['alert_rules']['groups'] = [
  {
    'name' => 'node_alerts',
    'rules' => [
      {
        'alert' => 'InstanceDown',
        'expr' => 'up == 0',
        'for' => '5m',
        'labels' => { 'severity' => 'critical' },
        'annotations' => {
          'summary' => 'Instance {{ $labels.instance }} down',
          'description' => '{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes.',
        },
      },
      {
        'alert' => 'HighCpuUsage',
        'expr' => '100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80',
        'for' => '10m',
        'labels' => { 'severity' => 'warning' },
        'annotations' => {
          'summary' => 'High CPU usage on {{ $labels.instance }}',
          'description' => 'CPU usage is above 80% on {{ $labels.instance }} for more than 10 minutes.',
        },
      },
      {
        'alert' => 'HighMemoryUsage',
        'expr' => '(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85',
        'for' => '10m',
        'labels' => { 'severity' => 'warning' },
        'annotations' => {
          'summary' => 'High memory usage on {{ $labels.instance }}',
          'description' => 'Memory usage is above 85% on {{ $labels.instance }} for more than 10 minutes.',
        },
      },
      {
        'alert' => 'DiskSpaceLow',
        'expr' => '(node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"} / node_filesystem_size_bytes{fstype!~"tmpfs|overlay"}) * 100 < 15',
        'for' => '10m',
        'labels' => { 'severity' => 'warning' },
        'annotations' => {
          'summary' => 'Low disk space on {{ $labels.instance }}',
          'description' => 'Disk space is below 15% on {{ $labels.instance }} ({{ $labels.mountpoint }}).',
        },
      },
    ],
  },
  {
    'name' => 'kubernetes_alerts',
    'rules' => [
      {
        'alert' => 'KubeAPIServerDown',
        'expr' => 'up{job="kube_apiserver"} == 0',
        'for' => '5m',
        'labels' => { 'severity' => 'critical' },
        'annotations' => {
          'summary' => 'Kubernetes API Server is down',
          'description' => 'The Kubernetes API Server on {{ $labels.instance }} has been unreachable for more than 5 minutes.',
        },
      },
      {
        'alert' => 'KubeletDown',
        'expr' => 'up{job="kubelet"} == 0',
        'for' => '5m',
        'labels' => { 'severity' => 'critical' },
        'annotations' => {
          'summary' => 'Kubelet down on {{ $labels.instance }}',
          'description' => 'Kubelet on {{ $labels.instance }} has been unreachable for more than 5 minutes.',
        },
      },
      {
        'alert' => 'EtcdDown',
        'expr' => 'up{job="etcd"} == 0',
        'for' => '5m',
        'labels' => { 'severity' => 'critical' },
        'annotations' => {
          'summary' => 'etcd is down',
          'description' => 'etcd on {{ $labels.instance }} has been unreachable for more than 5 minutes.',
        },
      },
      {
        'alert' => 'KubeSchedulerDown',
        'expr' => 'up{job="kube_scheduler"} == 0',
        'for' => '5m',
        'labels' => { 'severity' => 'critical' },
        'annotations' => {
          'summary' => 'Kubernetes Scheduler is down',
          'description' => 'The Kubernetes Scheduler on {{ $labels.instance }} has been unreachable for more than 5 minutes.',
        },
      },
      {
        'alert' => 'KubeControllerManagerDown',
        'expr' => 'up{job="kube_controller_manager"} == 0',
        'for' => '5m',
        'labels' => { 'severity' => 'critical' },
        'annotations' => {
          'summary' => 'Kubernetes Controller Manager is down',
          'description' => 'The Kubernetes Controller Manager on {{ $labels.instance }} has been unreachable for more than 5 minutes.',
        },
      },

    ],
  },
  {
    'name' => 'service_alerts',
    'rules' => [
      {
        'alert' => 'JenkinsDown',
        'expr' => 'up{job="jenkins"} == 0',
        'for' => '5m',
        'labels' => { 'severity' => 'critical' },
        'annotations' => {
          'summary' => 'Jenkins is down',
          'description' => 'Jenkins on {{ $labels.instance }} has been unreachable for more than 5 minutes.',
        },
      },
      {
        'alert' => 'GrafanaDown',
        'expr' => 'up{job="grafana"} == 0',
        'for' => '5m',
        'labels' => { 'severity' => 'warning' },
        'annotations' => {
          'summary' => 'Grafana is down',
          'description' => 'Grafana on {{ $labels.instance }} has been unreachable for more than 5 minutes.',
        },
      },
    ],
  },
  {
    'name' => 'chef_client_alerts',
    'rules' => [
      {
        'alert' => 'ChefClientTimerInactive',
        'expr' => 'chef_client_timer_active == 0',
        'for' => '5m',
        'labels' => { 'severity' => 'critical' },
        'annotations' => {
          'summary' => 'Chef client timer inactive on {{ $labels.instance }}',
          'description' => 'The chef-client.timer systemd unit is not active on {{ $labels.instance }} for more than 5 minutes.',
        },
      },
      {
        'alert' => 'ChefClientRunFailed',
        'expr' => 'chef_client_last_run_success == 0',
        'for' => '10m',
        'labels' => { 'severity' => 'warning' },
        'annotations' => {
          'summary' => 'Chef client run failed on {{ $labels.instance }}',
          'description' => 'The last chef-client run on {{ $labels.instance }} has been in a failed state for more than 10 minutes.',
        },
      },
      {
        'alert' => 'ChefClientRunStale',
        'expr' => 'time() - chef_client_last_run_timestamp_seconds > 3600',
        'for' => '5m',
        'labels' => { 'severity' => 'critical' },
        'annotations' => {
          'summary' => 'Chef client run stale on {{ $labels.instance }}',
          'description' => 'Chef client on {{ $labels.instance }} has not run for over 1 hour (expected every 30 minutes).',
        },
      },
    ],
  },
]
