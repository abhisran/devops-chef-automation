# prometheus-server Cookbook

Downloads and installs Prometheus from official GitHub releases and deploys a fully attribute-driven configuration with scrape targets and alert rules. Managed as a systemd service.

## Requirements

### Platforms

- Debian/Ubuntu
- RHEL/CentOS/Fedora

### Chef

- Chef 16+

## Attributes

### Core Settings

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['prometheus']['server']['version']` | Prometheus version to install | `2.53.3` |
| `node['prometheus']['server']['install_dir']` | Binary installation directory | `/opt/prometheus` |
| `node['prometheus']['server']['config_dir']` | Configuration directory | `/etc/prometheus` |
| `node['prometheus']['server']['data_dir']` | TSDB data directory | `/var/lib/prometheus` |
| `node['prometheus']['server']['user']` | Prometheus system user | `prometheus` |
| `node['prometheus']['server']['group']` | Prometheus system group | `prometheus` |

### Network Settings

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['prometheus']['server']['port']` | Web UI / API listen port | `9090` |
| `node['prometheus']['server']['listen_address']` | Listen address | `0.0.0.0` |

### Storage Settings

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['prometheus']['server']['retention_time']` | TSDB retention period | `15d` |
| `node['prometheus']['server']['retention_size']` | TSDB max size (`0` = unlimited) | `0` |

### Scrape Settings

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['prometheus']['server']['scrape_interval']` | Global scrape interval | `15s` |
| `node['prometheus']['server']['evaluation_interval']` | Rule evaluation interval | `15s` |
| `node['prometheus']['server']['scrape_timeout']` | Scrape timeout | `10s` |

### Scrape Configs

`node['prometheus']['server']['scrape_configs']` is an array of hashes with the following keys:

| Key | Description | Required |
|-----|-------------|----------|
| `job_name` | Scrape job name | Yes |
| `targets` | Array of `host:port` targets | Yes |
| `metrics_path` | Metrics endpoint path | No (default `/metrics`) |
| `scheme` | `http` or `https` | No (default `http`) |
| `scrape_interval` | Per-job scrape interval override | No |
| `labels` | Hash of additional labels | No |

Default scrape configs include Prometheus self-monitoring and node_exporter targets.

### Alertmanager Integration

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['prometheus']['server']['alertmanager']['enabled']` | Enable Alertmanager integration | `false` |
| `node['prometheus']['server']['alertmanager']['targets']` | Alertmanager target(s) | `['localhost:9093']` |

### Alert Rules

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['prometheus']['server']['alert_rules']['enabled']` | Deploy alert rule files | `true` |
| `node['prometheus']['server']['alert_rules']['groups']` | Array of alert rule groups | See below |

Default alert rules:

| Alert | Expression | For | Severity |
|-------|-----------|-----|----------|
| `InstanceDown` | `up == 0` | 5m | critical |
| `HighCpuUsage` | CPU idle < 20% (5m avg) | 10m | warning |
| `HighMemoryUsage` | Available memory < 15% | 10m | warning |
| `DiskSpaceLow` | Filesystem available < 15% | 10m | warning |

## Recipes

### default

Includes all other recipes in the correct order.

### install

Creates the `prometheus` user and group. Downloads the Prometheus release tarball from GitHub, extracts the `prometheus` and `promtool` binaries to the install directory, and copies the console templates to the config directory. Symlinks binaries to `/usr/local/bin`.

### config

Deploys the main `prometheus.yml` configuration from attributes, including global settings, scrape configs, and Alertmanager targets. Deploys alert rule files to the rules directory. Validates the configuration with `promtool check config` after changes.

### service

Deploys a systemd service unit for Prometheus and enables/starts the service. Supports graceful reload via `SIGHUP` when configuration changes.

## Centralized Version Management

This cookbook supports loading version attributes from the `app_versions` Chef Vault. If the vault exists, it overrides the default attribute values at compile time. If the vault is not available, the hardcoded defaults in `attributes/default.rb` are used.

### Vault Keys

| Vault Key | Overrides Attribute |
|-----------|--------------------|
| `prometheus.server_version` | `node['prometheus']['server']['version']` |

### Setup

```bash
knife vault create app_versions default \
  '{"prometheus":{"server_version":"2.53.3"}}' \
  --search "role:prometheus-server" \
  --admins "admin_user"
```

## Usage

### Install & Upload

```bash
cd prometheus/prometheus-server
berks install    # resolves cookbook dependencies
berks upload     # uploads cookbook + dependencies to Chef Server
```

Then add the cookbook to your node's run list:

```ruby
run_list 'recipe[prometheus-server]'
```

### Customize Scrape Targets

Override the scrape configs to monitor your infrastructure:

```ruby
default_attributes(
  'prometheus' => {
    'server' => {
      'scrape_configs' => [
        {
          'job_name' => 'prometheus',
          'targets' => ['localhost:9090']
        },
        {
          'job_name' => 'node_exporter',
          'targets' => [
            '<MASTER_IP>:9100',
            '<WORKER_1_IP>:9100',
            '<WORKER_2_IP>:9100'
          ]
        },
        {
          'job_name' => 'jenkins',
          'targets' => ['<JENKINS_IP>:8080'],
          'metrics_path' => '/prometheus'
        }
      ]
    }
  }
)
```

### Enable Alertmanager

```ruby
default_attributes(
  'prometheus' => {
    'server' => {
      'alertmanager' => {
        'enabled' => true,
        'targets' => ['<ALERTMANAGER_IP>:9093']
      }
    }
  }
)
```

### Custom Alert Rules

Add custom alert rule groups:

```ruby
default_attributes(
  'prometheus' => {
    'server' => {
      'alert_rules' => {
        'groups' => [
          {
            'name' => 'custom_alerts',
            'rules' => [
              {
                'alert' => 'HighRequestLatency',
                'expr' => 'http_request_duration_seconds{quantile="0.99"} > 1',
                'for' => '10m',
                'labels' => { 'severity' => 'warning' },
                'annotations' => {
                  'summary' => 'High request latency on {{ $labels.instance }}'
                }
              }
            ]
          }
        ]
      }
    }
  }
)
```

### Access the Web UI

After running `chef-client`, access the Prometheus web interface at:

```
http://<prometheus-server-ip>:9090
```

## License

All Rights Reserved

## Author

Abhishek Ranjan
