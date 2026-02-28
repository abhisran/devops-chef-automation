# Node Exporter version and installation
default['prometheus']['node_exporter']['version'] = '1.8.2'
default['prometheus']['node_exporter']['install_dir'] = '/opt/node_exporter'
default['prometheus']['node_exporter']['user'] = 'node_exporter'
default['prometheus']['node_exporter']['group'] = 'node_exporter'

# Network settings
default['prometheus']['node_exporter']['port'] = 9100
default['prometheus']['node_exporter']['listen_address'] = '0.0.0.0'

# Textfile collector directory (for custom metrics via .prom files)
default['prometheus']['node_exporter']['textfile_dir'] = '/var/lib/node_exporter/textfile_collector'

# Collectors to enable (in addition to defaults)
# See: https://github.com/prometheus/node_exporter#collectors
default['prometheus']['node_exporter']['enabled_collectors'] = %w(
  textfile
  systemd
)

# Collectors to explicitly disable
default['prometheus']['node_exporter']['disabled_collectors'] = []

# Additional command-line flags
# Example: { '--collector.diskstats.device-exclude' => '^(ram|loop|fd)\\d+$' }
default['prometheus']['node_exporter']['extra_flags'] = {}
