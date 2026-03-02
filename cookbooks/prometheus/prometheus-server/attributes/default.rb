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
]
