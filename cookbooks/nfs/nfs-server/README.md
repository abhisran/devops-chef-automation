# nfs-server Cookbook

Installs and configures an NFS server for shared storage in the homelab.

## What It Does

1. **install.rb** — Installs `nfs-kernel-server` and `nfs-common` packages
2. **config.rb** — Creates shared directories and deploys `/etc/exports`
3. **service.rb** — Enables and starts the `nfs-kernel-server` service
4. **firewall** — Opens NFS ports (2049/tcp, 2049/udp, 111/tcp, 111/udp) via the shared firewall cookbook

## Attributes

| Attribute | Default | Description |
|---|---|---|
| `['nfs']['server']['exports_file']` | `/etc/exports` | Path to exports config |
| `['nfs']['server']['exports']` | See `attributes/default.rb` | Array of export definitions |
| `['firewall']['rule_groups']['nfs_server']['enabled']` | `true` | Enable NFS firewall rules |

## Usage

Add `nfs-server` to the node's run list:

```json
{
  "run_list": [
    "recipe[apt]",
    "recipe[package]",
    "recipe[nfs-server]",
    "recipe[nagios-client]",
    "recipe[prometheus-client]"
  ]
}
```

## Adding Exports

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
