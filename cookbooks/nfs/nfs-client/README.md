# NFS Client Cookbook

> **Author:** Abhishek Ranjan
> **Cookbook:** `nfs-client`
> **Last Updated:** 2025

---

## Overview

The `nfs-client` cookbook installs the necessary tools to mount NFS shares and manages persistent mount points on Debian/Ubuntu systems.

**Key facts:**
- Installs `nfs-common` package
- Manages local mount points and `/etc/fstab`
- Fully attribute-driven mount definitions
- Integrates with Nagios and Prometheus for node-level monitoring

---

## Infrastructure Details

| Component | Value |
|-----------|-------|
| **Package** | `nfs-common` |
| **Mount Points** | User-defined via attributes |
| **Supported Protocols** | NFSv3, NFSv4 |
| **Default NFS Server** | `192.168.1.79` |

---

## Recipes

### default
Includes `apt`, `package`, `nfs-client::install`, `nfs-client::mount`, `nagios-client`, and `prometheus-client` to ensure the client is fully configured and monitored.

### install
Installs the `nfs-common` package, which provides the `mount.nfs` utility.

### mount
Iterates through `node['nfs']['client']['mounts']` and for each entry:
- Creates the local directory (mount point) if it doesn't exist
- Mounts the remote share with specified options
- Ensures the mount is persistent across reboots (managed by Chef's `mount` resource)

---

## Attributes

| Attribute | Default | Description |
|-----------|---------|-------------|
| `node['nfs']['client']['mounts']` | `[]` | Array of mount definitions (local_path, remote_path, options) |

---

## Usage

### Install & Upload

```bash
cd nfs/nfs-client
berks install    # resolves cookbook dependencies
berks upload     # uploads cookbook + dependencies to Chef Server
```

### Assign to Node

Add `nfs-client` to the node's run list and define the mounts in attributes.

### Example Attribute Configuration (in a Role or Environment)

```ruby
default_attributes(
  'nfs' => {
    'client' => {
      'mounts' => [
        {
          'local_path' => '/mnt/shared',
          'remote_path' => '192.168.1.79:/srv/nfs/shared',
          'options' => 'rw,sync,hard,intr'
        }
      ]
    }
  }
)
```

## License

All Rights Reserved

## Author

Abhishek Ranjan
