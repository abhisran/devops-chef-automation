# k8s-master

Chef cookbook to configure a Kubernetes master node with:

- Container runtime (containerd)
- Kubernetes components (kubeadm, kubelet, kubectl)
- Kubernetes master initialization
- Weave CNI plugin
- Jenkins CI/CD RBAC (ServiceAccount + namespace-scoped Roles)
- etcd snapshot backup with local + remote retention

## Requirements

### Platforms

- Debian/Ubuntu

### Chef

- Chef 16+

## Attributes

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['kubernetes']['version']` | Kubernetes version | `1.32` |
| `node['kubernetes']['packages']` | K8s packages to install | `kubelet kubeadm kubectl` |
| `node['kubernetes']['cni_version']` | CNI plugin version | `1.4.0` |
| `node['kubernetes']['network_plugin']['name']` | Network plugin name | `weave` |
| `node['kubernetes']['rbac']['jenkins']['enabled']` | Enable Jenkins RBAC setup | `true` |
| `node['kubernetes']['rbac']['jenkins']['service_account']` | ServiceAccount name for Jenkins | `jenkins-deployer` |
| `node['kubernetes']['rbac']['jenkins']['namespace']` | Namespace for the ServiceAccount | `ci-cd` |
| `node['kubernetes']['rbac']['jenkins']['deploy_namespaces']` | Namespaces Jenkins can deploy to | `staging production` |
| `node['kubernetes']['etcd_backup']['enabled']` | Enable etcd backup script deployment | `true` |
| `node['kubernetes']['etcd_backup']['backup_dir']` | Local backup directory | `/var/backups/etcd` |
| `node['kubernetes']['etcd_backup']['script_path']` | Path to the backup script | `/usr/local/bin/etcd-backup.sh` |
| `node['kubernetes']['etcd_backup']['etcdctl_version']` | etcdctl version to install | `3.5.27` |
| `node['kubernetes']['etcd_backup']['retention_days']` | Days to keep local backups | `7` |
| `node['kubernetes']['etcd_backup']['etcd_endpoints']` | etcd endpoint URL | `https://127.0.0.1:2379` |
| `node['kubernetes']['etcd_backup']['cert_dir']` | etcd PKI certificate directory | `/etc/kubernetes/pki/etcd` |
| `node['kubernetes']['etcd_backup']['remote']['enabled']` | Enable remote copy via SCP | `true` |
| `node['kubernetes']['etcd_backup']['remote']['user']` | SSH user for remote host | `backup` |
| `node['kubernetes']['etcd_backup']['remote']['host']` | Remote backup host | `192.168.1.50` |
| `node['kubernetes']['etcd_backup']['remote']['path']` | Remote backup directory | `/backups/etcd` |
| `node['kubernetes']['etcd_backup']['remote']['retention_days']` | Days to keep remote backups | `7` |

## Recipes

### default

Includes all other recipes in the correct order.

### containerd

Installs and configures the containerd container runtime with SystemdCgroup support.

### kubernetes

Disables swap, adds the Kubernetes apt repository, and installs kubeadm, kubelet, and kubectl. Holds packages at the current version.

### master

Pulls required images, initializes the Kubernetes master with `kubeadm init`, configures kubectl for the root user, and installs the Weave network plugin.

### etcd_backup

Installs `etcdctl` and deploys an etcd snapshot backup script on the master node. The `etcdctl` binary is downloaded from the official etcd releases (not included on the host by default in kubeadm clusters). The script:

1. Takes an etcd snapshot using `etcdctl snapshot save` with the cluster's PKI certificates
2. Saves the snapshot to the local backup directory with a timestamp
3. Verifies snapshot integrity with `etcdctl snapshot status`
4. Rotates local backups older than the configured retention period
5. Copies the snapshot to a remote host via SCP (if enabled)
6. Rotates remote backups older than the configured retention period

The script supports a `--verify` flag to check the latest backup without taking a new one.

Can be disabled by setting `node['kubernetes']['etcd_backup']['enabled']` to `false`.

**Designed to be triggered by a Jenkins pipeline** — see the `Jenkins-Pipelines/etcd-backup/` repo for the Jenkinsfile that runs this script daily via cron.

### rbac

Creates Kubernetes RBAC resources for Jenkins CI/CD pipelines. This recipe:

1. Creates namespaces: `ci-cd`, `staging`, `production`
2. Creates a `jenkins-deployer` ServiceAccount in `ci-cd`
3. Creates a long-lived token Secret for the ServiceAccount
4. Creates namespace-scoped Roles in `staging` and `production` with permissions to manage deployments, services, pods, configmaps, secrets, ingresses, jobs, and cronjobs
5. Creates RoleBindings linking the ServiceAccount to each namespace

Can be disabled by setting `node['kubernetes']['rbac']['jenkins']['enabled']` to `false`.

**After running chef-client**, extract the token for kubeconfig setup:

```bash
kubectl -n ci-cd get sa,secret
kubectl -n staging get role,rolebinding
kubectl -n production get role,rolebinding
```

See the [jenkins-agent README](../../jenkins/jenkins-agent/README.md#kubeconfig-vault-setup) for instructions on extracting the token and storing the kubeconfig in Chef Vault.

### RBAC Permissions

The `jenkins-deployer` Role grants the following permissions in each deploy namespace:

| API Group | Resources | Verbs |
|-----------|-----------|-------|
| `apps` | deployments, replicasets, statefulsets | get, list, watch, create, update, patch, delete |
| (core) | services, pods, configmaps, secrets, persistentvolumeclaims | get, list, watch, create, update, patch, delete |
| `networking.k8s.io` | ingresses | get, list, watch, create, update, patch, delete |
| `batch` | jobs, cronjobs | get, list, watch, create, update, patch, delete |

Jenkins **cannot** access `kube-system`, `default`, or any other namespace not listed in `deploy_namespaces`.

## Usage

### Install & Upload

```bash
cd kubernetes/k8s-master
berks install    # resolves cookbook dependencies
berks upload     # uploads cookbook + dependencies to Chef Server
```

Then add the cookbook to your node's run list:

```ruby
run_list 'recipe[k8s-master]'
```

To add additional deploy namespaces:

```ruby
default_attributes(
  'kubernetes' => {
    'rbac' => {
      'jenkins' => {
        'deploy_namespaces' => %w(staging production dev)
      }
    }
  }
)
```

To disable Jenkins RBAC:

```ruby
default_attributes(
  'kubernetes' => {
    'rbac' => {
      'jenkins' => {
        'enabled' => false
      }
    }
  }
)
```

### etcd Backup Configuration

Customize the remote backup destination:

```ruby
default_attributes(
  'kubernetes' => {
    'etcd_backup' => {
      'retention_days' => 14,
      'remote' => {
        'user' => 'backup',
        'host' => '192.168.1.50',
        'path' => '/backups/etcd'
      }
    }
  }
)
```

To disable etcd backup:

```ruby
default_attributes(
  'kubernetes' => {
    'etcd_backup' => {
      'enabled' => false
    }
  }
)
```

To run the backup manually on the master node:

```bash
sudo /usr/local/bin/etcd-backup.sh          # take a backup
sudo /usr/local/bin/etcd-backup.sh --verify  # verify the latest backup
```

## Author

Abhishek Ranjan
