# Firewall (UFW) Cookbook

> **Author:** Abhishek Ranjan
> **Cookbook:** `firewall`
> **Last Updated:** 2025

---

## Overview

The `firewall` cookbook manages UFW (Uncomplicated Firewall) on all nodes. It implements a default-deny incoming policy with role-based rule groups that open only necessary ports.

**Key facts:**
- Default deny incoming, allow outgoing
- SSH (22/tcp) always allowed first (safety net)
- Role-based rule groups (K8s, Jenkins, Nagios, Prometheus, NFS, etc.)
- Kubernetes-aware: configures IP forwarding and FORWARD policy
- Source-restricted rules for monitoring (NRPE)

---

## Infrastructure Details

| Component | Value |
|-----------|-------|
| **Firewall Tool** | UFW (Uncomplicated Firewall) |
| **Default Incoming** | `deny` |
| **Default Outgoing** | `allow` |
| **Default Routed** | `deny` (except K8s nodes: `allow`) |
| **Nagios Server IP** | `192.168.1.74` |

---

## Port Matrix

| Role | Port | Protocol | Purpose | Source Restriction |
|------|------|----------|---------|-------------------|
| **All nodes** | 22 | tcp | SSH | — |
| **All nodes** | 5666 | tcp | NRPE (Monitoring) | Nagios (192.168.1.74) |
| **All nodes** | 9100 | tcp | Node Exporter | — |
| **K8s Master** | 6443 | tcp | K8s API Server | — |
| **K8s Master** | 2379–2380 | tcp | etcd | — |
| **K8s Master** | 10250 | tcp | Kubelet API | — |
| **K8s Master** | 6783-6784 | tcp/udp | Weave CNI | — |
| **K8s Worker** | 30000–32767 | tcp | K8s NodePorts | — |
| **Jenkins** | 8080 | tcp | Jenkins UI | — |
| **Nagios** | 80 | tcp | Nagios UI | — |
| **Prometheus** | 9090 | tcp | Prometheus UI | — |
| **Grafana** | 3000 | tcp | Grafana UI | — |
| **NFS Server** | 2049, 111 | tcp/udp | NFS / RPCbind | — |

---

## Recipes

### default
Includes `install`, `config`, and `service` in order. Skips if `node['firewall']['enabled']` is `false`.

### install
Installs the `ufw` package.

### config
Sets defaults, applies SSH safety rule, and iterates through enabled rule groups. For K8s nodes, enables IP forwarding and sets `DEFAULT_FORWARD_POLICY="ACCEPT"`.

### service
Enables UFW using `ufw --force enable`.

---

## Usage

### Enable Rule Groups

Set these via roles or environments:

```ruby
# Example for a Jenkins Server
default_attributes(
  'firewall' => {
    'rule_groups' => {
      'jenkins_server' => { 'enabled' => true }
    }
  }
)
```

### Adding Custom Rules

```ruby
default_attributes(
  'firewall' => {
    'rule_groups' => {
      'custom' => {
        'enabled' => true,
        'rules' => {
          'my_app' => { 'port' => '3000', 'protocol' => 'tcp', 'action' => 'allow' }
        }
      }
    }
  }
)
```

## License

All Rights Reserved

## Author

Abhishek Ranjan
