# Grafana version (installed via APT, version pinning is optional)
default['grafana']['server']['version'] = 'latest'

# Network settings
default['grafana']['server']['http_port'] = 3000
default['grafana']['server']['http_addr'] = '0.0.0.0'
default['grafana']['server']['domain'] = 'localhost'
default['grafana']['server']['root_url'] = '%(protocol)s://%(domain)s:%(http_port)s/'

# Paths
default['grafana']['server']['config_file'] = '/etc/grafana/grafana.ini'
default['grafana']['server']['provisioning_dir'] = '/etc/grafana/provisioning'
default['grafana']['server']['data_dir'] = '/var/lib/grafana'
default['grafana']['server']['log_dir'] = '/var/log/grafana'
default['grafana']['server']['dashboard_dir'] = '/var/lib/grafana/dashboards'

# Admin credentials (override via chef-vault in production)
default['grafana']['server']['admin_user'] = 'admin'
default['grafana']['server']['admin_password'] = 'admin'

# Anonymous access (read-only, useful for shared dashboards)
default['grafana']['server']['anonymous_enabled'] = false
default['grafana']['server']['anonymous_org_role'] = 'Viewer'

# Analytics
default['grafana']['server']['reporting_enabled'] = false
default['grafana']['server']['check_for_updates'] = false

# Metrics (enables /metrics endpoint for Prometheus scraping)
default['grafana']['server']['metrics_enabled'] = true

# Logging
default['grafana']['server']['log_mode'] = 'console file'
default['grafana']['server']['log_level'] = 'info'

# Datasources to provision
default['grafana']['server']['datasources'] = [
  {
    'name' => 'Prometheus',
    'type' => 'prometheus',
    'access' => 'proxy',
    'url' => 'http://192.168.1.77:9090',
    'is_default' => true,
    'editable' => false,
  },
]

# Firewall
default['firewall']['rule_groups']['grafana_server']['enabled'] = true
