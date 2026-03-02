# prometheus-client Cookbook

Downloads and installs Prometheus Node Exporter from official GitHub releases for system metrics collection. Exposes hardware and OS-level metrics (CPU, memory, disk, network, etc.) for scraping by a Prometheus server. Managed as a systemd service.

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
| `node['prometheus']['node_exporter']['version']` | Node Exporter version to install | `1.8.2` |
| `node['prometheus']['node_exporter']['install_dir']` | Binary installation directory | `/opt/node_exporter` |
| `node['prometheus']['node_exporter']['user']` | System user | `node_exporter` |
| `node['prometheus']['node_exporter']['group']` | System group | `node_exporter` |

### Network Settings

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['prometheus']['node_exporter']['port']` | Metrics listen port | `9100` |
| `node['prometheus']['node_exporter']['listen_address']` | Listen address | `0.0.0.0` |

### Collector Settings

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['prometheus']['node_exporter']['textfile_dir']` | Textfile collector directory | `/var/lib/node_exporter/textfile_collector` |
| `node['prometheus']['node_exporter']['enabled_collectors']` | Additional collectors to enable | `['textfile', 'systemd']` |
| `node['prometheus']['node_exporter']['disabled_collectors']` | Collectors to disable | `[]` |
| `node['prometheus']['node_exporter']['extra_flags']` | Additional CLI flags (hash) | `{}` |

## Recipes

### default

Includes all other recipes in the correct order.

### install

Creates the `node_exporter` user and group. Downloads the Node Exporter release tarball from GitHub, extracts the binary to the install directory, and symlinks it to `/usr/local/bin`.

### config

Ensures the textfile collector directory exists with correct permissions. Node Exporter is configured entirely via command-line flags in the systemd service unit.

### service

Deploys a systemd service unit for Node Exporter with all configured collectors and flags, then enables and starts the service.

## Centralized Version Management

This cookbook supports loading version attributes from the `app_versions` Chef Vault. If the vault exists, it overrides the default attribute values at compile time. If the vault is not available, the hardcoded defaults in `attributes/default.rb` are used.

### Vault Keys

| Vault Key | Overrides Attribute |
|-----------|--------------------|
| `prometheus.node_exporter_version` | `node['prometheus']['node_exporter']['version']` |

### Setup

```bash
knife vault create app_versions default \
  '{"prometheus":{"node_exporter_version":"1.8.2"}}' \
  --search "role:prometheus-client" \
  --admins "admin_user"
```

## Usage

### Install & Upload

```bash
cd prometheus/prometheus-client
berks install    # resolves cookbook dependencies
berks upload     # uploads cookbook + dependencies to Chef Server
```

Then add the cookbook to your node's run list:

```ruby
run_list 'recipe[prometheus-client]'
```

### Custom Collectors

Enable or disable specific collectors:

```ruby
default_attributes(
  'prometheus' => {
    'node_exporter' => {
      'enabled_collectors' => %w(textfile systemd processes),
      'disabled_collectors' => %w(infiniband nfs)
    }
  }
)
```

### Extra CLI Flags

Pass additional flags to the Node Exporter binary:

```ruby
default_attributes(
  'prometheus' => {
    'node_exporter' => {
      'extra_flags' => {
        '--collector.diskstats.device-exclude' => '^(ram|loop|fd)\\d+$',
        '--collector.filesystem.mount-points-exclude' => '^/(sys|proc|dev)($|/)'
      }
    }
  }
)
```

### Textfile Collector

The textfile collector is enabled by default. Drop `.prom` files into the textfile directory to expose custom metrics:

```bash
echo 'my_custom_metric 42' > /var/lib/node_exporter/textfile_collector/custom.prom
```

These metrics will appear in the Node Exporter `/metrics` output.

### Verify Metrics

After running `chef-client`, verify that Node Exporter is serving metrics:

```bash
curl http://localhost:9100/metrics
```

## License

All Rights Reserved

## Author

Abhishek Ranjan
