# nfs-client Cookbook

Installs and configures an NFS client for shared storage.

## What It Does

1. **install.rb** — Installs `nfs-common` package.
2. **mount.rb** — Creates local mount points and mounts remote NFS shares.
3. **default.rb** — Orchestrates the installation and mounting process.

## Attributes

| Attribute | Default | Description |
|---|---|---|
| `['nfs']['client']['mounts']` | `[]` | Array of NFS mount definitions |

## Usage

Add `nfs-client` to the node's run list and define the mounts in attributes.

### Example Attribute Configuration (in a Role or Environment)

```ruby
default_attributes(
  'nfs' => {
    'client' => {
      'mounts' => [
        {
          'local_path' => '/mnt/shared',
          'remote_path' => '192.168.1.10:/srv/nfs/shared',
          'options' => 'rw,sync,hard,intr'
        }
      ]
    }
  }
)
```

## Recipes

### default
Includes `apt`, `package`, `nfs-client::install`, `nfs-client::mount`, `nagios-client`, and `prometheus-client`.

### install
Installs the necessary `nfs-common` package.

### mount
Iterates through `node['nfs']['client']['mounts']` and ensures each is created and mounted.
