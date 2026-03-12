# Nagios Client (NRPE) Cookbook

> **Author:** Abhishek Ranjan
> **Cookbook:** `nagios-client`
> **Last Updated:** 2025

---

## Overview

The `nagios-client` cookbook installs and configures the NRPE (Nagios Remote Plugin Executor) daemon on monitored nodes. It includes a comprehensive suite of check commands for system health, Kubernetes components, Jenkins CI/CD, Prometheus, Grafana, and Chef client status.

**Key facts:**
- Installs `nagios-nrpe-server` and standard monitoring plugins
- Configures `allowed_hosts` to include the Nagios server (192.168.1.74)
- Provides 40+ pre-configured check commands
- Fully attribute-driven command definitions
- Integrates with UFW firewall (port 5666)

---

## Infrastructure Details

| Component | Value |
|-----------|-------|
| **NRPE Port** | `5666` |
| **Nagios Server IP** | `192.168.1.74` |
| **Daemon User** | `nagios` |
| **Config File** | `/etc/nagios/nrpe.cfg` |
| **Local Config** | `/etc/nagios/nrpe_local.cfg` (Debian/Ubuntu) |
| **Plugin Dir** | `/usr/lib/nagios/plugins` |

---

## Recipes

### default
Includes `install`, `config`, `service`, and `firewall` in the correct order.

### install
Creates the `nagios` user/group and installs the NRPE daemon and standard monitoring plugins via platform packages.

### config
Deploys the main `nrpe.cfg` and a local `nrpe_local.cfg`. It dynamically generates check commands based on the node's attributes and role.

### service
Enables and starts the NRPE service (e.g., `nagios-nrpe-server` on Debian).

---

## Check Commands Reference

### System Checks (All Nodes)
- `check_disk`: Disk usage (warn 20%, crit 10%)
- `check_load`: System load average
- `check_mem`: Memory usage (via `free`)
- `check_swap`: Swap usage
- `check_procs`: Total processes
- `check_ssh`: SSH service status
- `check_users`: Logged-in users

### Kubernetes Checks (K8s Nodes)
- `check_kubelet`, `check_containerd`, `check_kube_proxy`
- `check_kubelet_health`, `check_kube_proxy_health`, `check_dns_resolution`
- `check_apiserver_health`, `check_etcd_health` (Master only)

### Jenkins Checks
- `check_jenkins_process`, `check_jenkins_http` (Server)
- `check_jenkins_agent_user`, `check_jenkins_agent_workdir` (Agent)

### Infrastructure Checks
- `check_prometheus_http`, `check_grafana_http`
- `check_nfs_process`, `check_nfs_exports`
- `check_chef_client_timer`, `check_chef_client_status`

---

## Usage

### Install & Upload

```bash
cd nagios/nagios-client
berks install && berks upload
```

### Configure Nagios Server Access

The default Nagios server IP is `192.168.1.74`. To override:

```ruby
default_attributes(
  'nagios' => {
    'server' => { 'ip' => '<YOUR_NAGIOS_IP>' }
  }
)
```

### Adding Custom Commands

```ruby
default_attributes(
  'nagios' => {
    'nrpe' => {
      'custom_commands' => {
        'check_my_app' => '/usr/lib/nagios/plugins/check_http -H localhost -p 8080'
      }
    }
  }
)
```

## License

All Rights Reserved

## Author

Abhishek Ranjan
