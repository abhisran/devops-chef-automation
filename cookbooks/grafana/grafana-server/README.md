# grafana-server cookbook

Installs and configures [Grafana](https://grafana.com/) OSS for visualization and dashboarding.

## Overview

- Installs Grafana OSS via the official APT repository
- Configures `grafana.ini` with sensible defaults
- Provisions Prometheus as a default datasource
- Sets up dashboard provisioning from `/var/lib/grafana/dashboards`
- Manages the `grafana-server` systemd service
- Configures UFW firewall rules (port 3000)

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

## Dependencies

- `chef-vault` — for credential management
- `firewall` — UFW rule management
