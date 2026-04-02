# NFS client configuration

# List of NFS mounts
# Each mount should specify:
# - local_path: Where to mount locally
# - remote_path: Remote export path (e.g., '192.168.1.79:/srv/nfs/shared')
# - options: Mount options (default: 'rw,sync,hard,intr')
default['nfs']['client']['mounts'] = [
  {
    'local_path' => '/mnt/shared',
    'remote_path' => '192.168.1.79:/srv/nfs/shared',
    'options' => 'rw,sync,hard,intr'
  }
]
