# grafana-server Cookbook

Installs and configures [Grafana](https://grafana.com/) OSS for visualization and dashboarding.

## Overview

- Installs Grafana OSS via the official APT repository
- Configures `grafana.ini` with sensible defaults
- Uses **Unified Alerting** (`[unified_alerting]`) — legacy `[alerting]` was removed in Grafana 11+ and causes a startup crash if present
- Provisions Prometheus as a default datasource
- Sets up file-based dashboard provisioning from `/var/lib/grafana/dashboards`
- Manages the `grafana-server` systemd service
- Configures UFW firewall rules (port 3000)
- Supports centralized version management via the `app_versions` Chef Vault

## Infrastructure

| Component | Value |
|---|---|
| Grafana server | `192.168.1.78` |
| Prometheus datasource | `192.168.1.77:9090` |
| Grafana port | `3000` |
| Config file | `/etc/grafana/grafana.ini` |
| Provisioning dir | `/etc/grafana/provisioning/` |
| Dashboard dir | `/var/lib/grafana/dashboards` |

## Usage

Add `grafana-server` to the node's run list:

```json
{ "run_list": ["recipe[grafana-server]"] }
```

## Importing Dashboards

Popular community dashboards can be downloaded from [Grafana Dashboards](https://grafana.com/grafana/dashboards/) and placed in `/var/lib/grafana/dashboards/` as JSON files. Recommended dashboards:

- **1860** — Node Exporter Full
- **3662** — Prometheus 2.0 Overview
- **15757** — Kubernetes / Views / Global
- **13332** — kube-state-metrics v2

## Attributes

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['grafana']['server']['version']` | Grafana version (via APT) | `latest` |
| `node['grafana']['server']['http_port']` | HTTP listen port | `3000` |
| `node['grafana']['server']['http_addr']` | Bind address | `0.0.0.0` |
| `node['grafana']['server']['domain']` | Server domain | `localhost` |
| `node['grafana']['server']['admin_user']` | Web UI admin username | `admin` |
| `node['grafana']['server']['admin_password']` | Web UI admin password (override in production!) | `admin` |
| `node['grafana']['server']['anonymous_enabled']` | Enable anonymous read access | `false` |
| `node['grafana']['server']['metrics_enabled']` | Enable `/metrics` endpoint for Prometheus | `true` |
| `node['grafana']['server']['datasources']` | Datasources to provision | Prometheus at `192.168.1.77:9090` |
| `node['grafana']['server']['log_mode']` | Logging mode | `console file` |
| `node['grafana']['server']['log_level']` | Logging level | `info` |

## Recipes

### default

Loads optional version overrides from the `app_versions` Chef Vault, then includes `install`, `config`, `service`, and `firewall` in order.

### install

Adds the official Grafana GPG key and APT repository. Installs the `grafana` package.

### config

Deploys `grafana.ini` with all attribute-driven settings. Creates provisioning directories and deploys datasource and dashboard provider YAML files. Unified Alerting is enabled by default.

### service

Enables and starts the `grafana-server` systemd service.

## Centralized Version Management

This cookbook supports loading version attributes from the `app_versions` Chef Vault. If the vault exists, it overrides the default attribute values at compile time.

### Vault Keys

| Vault Key | Overrides Attribute |
|-----------|--------------------|
| `grafana.version` | `node['grafana']['server']['version']` |

### Setup

```bash
knife vault create app_versions default \
  '{"grafana":{"version":"12.4.0"}}' \
  --search "role:grafana-server" \
  --admins "admin_user"
```

## Dependencies

- `chef-vault` (~> 4.0) — for credential management
- `firewall` — UFW rule management
