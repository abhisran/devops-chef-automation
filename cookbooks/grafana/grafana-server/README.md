# Grafana Server Cookbook

> **Author:** Abhishek Ranjan
> **Cookbook:** `grafana-server`
> **Last Updated:** 2025

---

## Overview

Grafana OSS is the visualization and dashboarding layer of the monitoring stack. It connects to Prometheus as its primary datasource and provides web-based dashboards for infrastructure metrics. Installed via the official Grafana APT repository.

**Key facts:**
- Grafana OSS (open-source edition)
- Default version: `latest` (overridable)
- Uses **Unified Alerting** (`[unified_alerting]`)
- Provisions Prometheus datasource and file-based dashboards automatically

---

## Infrastructure Details

| Component | Value |
|-----------|-------|
| **Server IP** | `192.168.1.78` |
| **Port** | `3000` |
| **Datasource** | Prometheus at `192.168.1.77:9090` |
| **Config File** | `/etc/grafana/grafana.ini` |
| **Provisioning Dir** | `/etc/grafana/provisioning/` |
| **Dashboard Dir** | `/var/lib/grafana/dashboards` |

---

## Recipes

### default
Loads optional version overrides from the `app_versions` Chef Vault, then includes `install`, `config`, `service`, and `firewall` in order.

### install
Adds the official Grafana GPG key and APT repository, then installs the `grafana` package.

### config
- Deploys `grafana.ini` with all attribute-driven settings.
- Creates provisioning directories.
- Deploys datasource YAML (Prometheus at `192.168.1.77:9090`).
- Deploys dashboard provider YAML (file-based from `/var/lib/grafana/dashboards`).

### service
Enables and starts the `grafana-server` systemd service.

### firewall
Opens port 3000 via UFW using the `firewall` cookbook integration.

---

## Attributes

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['grafana']['server']['version']` | Grafana version (via APT) | `latest` |
| `node['grafana']['server']['http_port']` | HTTP listen port | `3000` |
| `node['grafana']['server']['admin_user']` | Web UI admin username | `admin` |
| `node['grafana']['server']['admin_password']` | Web UI admin password | `admin` |
| `node['grafana']['server']['datasources']` | Datasources to provision | Prometheus (default) |

---

## Usage

### Install & Upload

```bash
cd grafana/grafana-server
berks install    # resolves cookbook dependencies
berks upload     # uploads cookbook + dependencies to Chef Server
```

### Importing Dashboards

Place JSON files in `/var/lib/grafana/dashboards/`. Grafana auto-detects them. Recommended dashboards:

- **1860** — Node Exporter Full
- **3662** — Prometheus 2.0 Overview
- **15757** — Kubernetes / Views / Global
- **13332** — kube-state-metrics v2

## License

All Rights Reserved

## Author

Abhishek Ranjan
