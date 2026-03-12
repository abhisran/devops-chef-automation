# NFS server configuration
default['nfs']['server']['exports_file'] = '/etc/exports'
default['nfs']['server']['config_file'] = '/etc/nfs.conf'
default['nfs']['server']['common_config_file'] = '/etc/default/nfs-common'
default['nfs']['server']['lockd_modprobe_file'] = '/etc/modprobe.d/nfs-lockd.conf'

# Fixed ports for NFS services (to allow through firewall)
default['nfs']['server']['ports']['mountd'] = 32767
default['nfs']['server']['ports']['statd'] = 32765
default['nfs']['server']['ports']['lockd'] = 32768

# Default shared directories
# Each export: path, network CIDR, and NFS options
default['nfs']['server']['exports'] = [
  {
    'path' => '/srv/nfs/shared',
    'network' => '192.168.1.0/24',
    'options' => 'rw,sync,no_subtree_check,no_root_squash,insecure',
  },
]

# Firewall
default['firewall']['rule_groups']['nfs_server']['enabled'] = true
