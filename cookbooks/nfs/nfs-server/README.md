# NFS Server Cookbook

> **Author:** Abhishek Ranjan
> **Cookbook:** `nfs-server`
> **Last Updated:** 2025

---

## Overview

The `nfs-server` cookbook installs and configures an NFS (Network File System) server on Ubuntu/Debian for shared storage in the homelab. It manages the kernel-level NFS server, exports shared directories, and integrates with the monitoring and firewall stacks.

**Key facts:**
- Installs `nfs-kernel-server` and `nfs-common`
- Manages `/etc/exports` via attribute-driven templates
- Includes firewall integration (ports 2049, 111)
- Supports monitoring via Nagios and Prometheus

---

## Infrastructure Details

| Component | Value |
|-----------|-------|
| **Default Server IP** | `192.168.1.79` |
| **NFS Port** | `2049` (TCP/UDP) |
| **RPCbind Port** | `111` (TCP/UDP) |
| **Shared Directory** | `/srv/nfs/shared` (default) |
| **Config File** | `/etc/exports` |
| **Service Name** | `nfs-kernel-server` |

---

## Recipes

### default
Includes `install`, `config`, `service`, and `firewall` in the correct order.

### install
Installs `nfs-kernel-server` and `nfs-common` packages using the platform's package manager.

### config
- Creates the shared export directories (default: `/srv/nfs/shared`)
- Deploys the `/etc/exports` configuration from an ERB template
- Runs `exportfs -ra` on changes to reload exports without restarting the service

### service
Enables and starts the `nfs-kernel-server` service.

### firewall
Includes the shared `firewall` cookbook and opens NFS port 2049 and RPCbind port 111. The `nfs_server` rule group must be enabled via attributes.

---

## Attributes

| Attribute | Default | Description |
|-----------|---------|-------------|
| `node['nfs']['server']['exports_file']` | `/etc/exports` | Path to the exports configuration file |
| `node['nfs']['server']['exports']` | `[{'path' => '/srv/nfs/shared', ...}]` | Array of export definitions (path, network, options) |
| `node['firewall']['rule_groups']['nfs_server']['enabled']` | `true` | Enable NFS firewall rules |

---

## Usage

### Install & Upload

```bash
cd nfs/nfs-server
berks install    # resolves cookbook dependencies
berks upload     # uploads cookbook + dependencies to Chef Server
```

### Assign to Node

Add `nfs-server` to the node's run list:

```ruby
run_list [
  'recipe[apt]',
  'recipe[package]',
  'recipe[nfs-server]',
  'recipe[nagios-client]',
  'recipe[prometheus-client]'
]
```

### Adding Custom Exports

Override the `exports` attribute in a role or environment:

```ruby
default['nfs']['server']['exports'] = [
  {
    'path' => '/srv/nfs/shared',
    'network' => '192.168.1.0/24',
    'options' => 'rw,sync,no_subtree_check,no_root_squash',
  },
  {
    'path' => '/srv/nfs/backups',
    'network' => '192.168.1.0/24',
    'options' => 'rw,sync,no_subtree_check',
  },
]
```

## License

All Rights Reserved

## Author

Abhishek Ranjan
