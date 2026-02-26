# firewall Cookbook

Installs and configures **UFW (Uncomplicated Firewall)** on all nodes with attribute-driven, role-based port rules.

- **Default deny** incoming, allow outgoing
- SSH always allowed first (safety net before enabling UFW)
- Rule groups per role — enable the groups that match each node's function
- Source-restricted rules for monitoring ports (NRPE, Node Exporter)
- Kubernetes-aware: configures IP forwarding and FORWARD policy for pod networking

## Requirements

### Platforms

- Debian/Ubuntu

### Chef

- Chef 16+

## Port Matrix

All ports managed by this cookbook, organized by role:

| Role | Port | Protocol | Purpose | Source Restriction |
|------|------|----------|---------|-------------------|
| **All nodes** | 22 | tcp | SSH | — |
| **All nodes** | 5666 | tcp | NRPE (Nagios monitoring) | Nagios server (192.168.1.55) |
| **All nodes** | 9100 | tcp | Prometheus Node Exporter | — |
| **K8s Master** | 6443 | tcp | Kubernetes API Server | — |
| **K8s Master** | 2379–2380 | tcp | etcd client communication | — |
| **K8s Master** | 2381 | tcp | etcd health endpoint | — |
| **K8s Master** | 10250 | tcp | Kubelet API | — |
| **K8s Master** | 10259 | tcp | kube-scheduler HTTPS | — |
| **K8s Master** | 10257 | tcp | kube-controller-manager HTTPS | — |
| **K8s Master** | 10256 | tcp | kube-proxy healthz | — |
| **K8s Master** | 10248 | tcp | kubelet healthz | — |
| **K8s Master** | 6783 | tcp/udp | Weave Net | — |
| **K8s Master** | 6784 | udp | Weave Net FastDP | — |
| **K8s Worker** | 10250 | tcp | Kubelet API | — |
| **K8s Worker** | 10256 | tcp | kube-proxy healthz | — |
| **K8s Worker** | 10248 | tcp | kubelet healthz | — |
| **K8s Worker** | 30000–32767 | tcp | Kubernetes NodePort range | — |
| **K8s Worker** | 6783 | tcp/udp | Weave Net | — |
| **K8s Worker** | 6784 | udp | Weave Net FastDP | — |
| **Jenkins Server** | 8080 | tcp | Jenkins HTTP | — |
| **Nagios Server** | 80 | tcp | Apache HTTP (Nagios UI) | — |
| **Prometheus Server** | 9090 | tcp | Prometheus UI/API | — |

## Attributes

### Global Settings

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['firewall']['enabled']` | Enable/disable the entire cookbook | `true` |
| `node['firewall']['default_policy_incoming']` | Default incoming policy | `deny` |
| `node['firewall']['default_policy_outgoing']` | Default outgoing policy | `allow` |
| `node['firewall']['default_policy_routed']` | Default routed policy | `deny` |
| `node['firewall']['logging']` | UFW logging level (off/low/medium/high/full) | `low` |

### Rule Groups

Each rule group has an `enabled` flag and a `rules` hash. Enable the groups matching each node's role:

| Rule Group | Default | Description |
|------------|---------|-------------|
| `common` | **enabled** | SSH (22/tcp) |
| `nagios_client` | **enabled** | NRPE (5666/tcp) from Nagios server |
| `prometheus_client` | **enabled** | Node Exporter (9100/tcp) |
| `k8s_master` | disabled | All Kubernetes master ports + Weave CNI |
| `k8s_worker` | disabled | Kubelet, NodePorts, Weave CNI |
| `jenkins_server` | disabled | Jenkins HTTP (8080/tcp) |
| `nagios_server` | disabled | Apache HTTP (80/tcp) |
| `prometheus_server` | disabled | Prometheus (9090/tcp) |

### Rule Format

Each rule is a hash entry under `node['firewall']['rule_groups'][<group>]['rules']`:

```ruby
'rule_name' => {
  'port'     => '8080',          # port or range (e.g. '30000:32767')
  'protocol' => 'tcp',           # tcp or udp
  'action'   => 'allow',         # allow or deny
  'source'   => '192.168.1.55',  # optional — restrict to source IP/CIDR
  'comment'  => 'Jenkins HTTP',  # UFW rule comment
}
```

## Recipes

### default

Includes `install`, `config`, and `service` in order. Skips entirely if `node['firewall']['enabled']` is `false`.

### install

Installs the `ufw` package.

### config

Sets UFW default policies and logging, then applies all enabled rule groups. SSH is always applied first as a safety net.

On Kubernetes nodes (when `k8s_master` or `k8s_worker` groups are enabled), the recipe also:
- Sets `DEFAULT_FORWARD_POLICY="ACCEPT"` in `/etc/default/ufw` (required for pod-to-pod traffic)
- Enables `net/ipv4/ip_forward=1` in `/etc/ufw/sysctl.conf`
- Enables `net/bridge/bridge-nf-call-iptables=1` in `/etc/ufw/sysctl.conf`

### service

Enables UFW with `ufw --force enable` (idempotent — skips if already active).

## Usage

### Install & Upload

```bash
cd system/firewall
berks install
berks upload
```

Add to every node's run list (before other cookbooks):

```ruby
run_list 'recipe[firewall]'
```

### Role Examples

#### Kubernetes Master

```ruby
default_attributes(
  'firewall' => {
    'rule_groups' => {
      'k8s_master' => { 'enabled' => true }
    }
  }
)
```

#### Kubernetes Worker

```ruby
default_attributes(
  'firewall' => {
    'rule_groups' => {
      'k8s_worker' => { 'enabled' => true }
    }
  }
)
```

#### Jenkins Server

```ruby
default_attributes(
  'firewall' => {
    'rule_groups' => {
      'jenkins_server' => { 'enabled' => true }
    }
  }
)
```

#### Nagios + Prometheus Server (co-hosted)

```ruby
default_attributes(
  'firewall' => {
    'rule_groups' => {
      'nagios_server' => { 'enabled' => true },
      'prometheus_server' => { 'enabled' => true }
    }
  }
)
```

### Adding Custom Rules

Add rules to any group or create new groups via role/environment attributes:

```ruby
default_attributes(
  'firewall' => {
    'rule_groups' => {
      'custom' => {
        'enabled' => true,
        'rules' => {
          'my_app' => {
            'port' => '3000',
            'protocol' => 'tcp',
            'action' => 'allow',
            'comment' => 'My application'
          }
        }
      }
    }
  }
)
```

### Restricting Node Exporter by Source

To restrict Node Exporter access to the Prometheus server only:

```ruby
default_attributes(
  'firewall' => {
    'rule_groups' => {
      'prometheus_client' => {
        'rules' => {
          'node_exporter' => {
            'source' => '192.168.1.55'
          }
        }
      }
    }
  }
)
```

### Disabling the Firewall

```ruby
default_attributes(
  'firewall' => {
    'enabled' => false
  }
)
```

## Author

Abhishek Ranjan
