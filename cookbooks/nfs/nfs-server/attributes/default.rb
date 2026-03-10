# NFS server configuration
default['nfs']['server']['exports_file'] = '/etc/exports'

# Default shared directories
# Each export: path, network CIDR, and NFS options
default['nfs']['server']['exports'] = [
  {
    'path' => '/srv/nfs/shared',
    'network' => '192.168.1.0/24',
    'options' => 'rw,sync,no_subtree_check,no_root_squash',
  },
]

# Firewall
default['firewall']['rule_groups']['nfs_server']['enabled'] = true
