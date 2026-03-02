# k8s-worker

Chef cookbook to configure a Kubernetes worker node with:

- Container runtime (containerd)
- Kubernetes components (kubeadm, kubelet, kubectl)
- Node preparation for joining a cluster

## Requirements

### Platforms

- Debian/Ubuntu

### Chef

- Chef 16+

## Attributes

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['kubernetes']['version']` | Kubernetes version | `1.33` |
| `node['kubernetes']['packages']` | K8s packages to install | `kubelet kubeadm kubectl` |
| `node['kubernetes']['cni_version']` | CNI plugin version | `1.4.0` |

## Recipes

### default

Includes all other recipes in the correct order.

### containerd

Installs and configures the containerd container runtime from the official Docker apt repository. Loads the `overlay` and `br_netfilter` kernel modules, sets required sysctl parameters, and configures containerd with SystemdCgroup support. Installs CNI plugins and holds the containerd package to prevent accidental upgrades.

### kubernetes

Disables swap, adds the Kubernetes apt repository, and installs kubeadm, kubelet, and kubectl. Holds packages at the current version to prevent accidental upgrades.

### worker

Prepares the node for joining a Kubernetes cluster. After running `chef-client`, you must manually run the `kubeadm join` command provided by the master node to join the cluster.

## Centralized Version Management

This cookbook supports loading version attributes from the `app_versions` Chef Vault. If the vault exists, it overrides the default attribute values at compile time. If the vault is not available, the hardcoded defaults in `attributes/default.rb` are used.

### Vault Keys

| Vault Key | Overrides Attribute |
|-----------|--------------------|
| `kubernetes.version` | `node['kubernetes']['version']` |
| `kubernetes.cni_version` | `node['kubernetes']['cni_version']` |

### Setup

```bash
knife vault create app_versions default \
  '{"kubernetes":{"version":"1.33","cni_version":"1.4.0"}}' \
  --search "role:k8s-worker" \
  --admins "admin_user"
```

## Usage

### Install & Upload

```bash
cd kubernetes/k8s-worker
berks install    # resolves cookbook dependencies
berks upload     # uploads cookbook + dependencies to Chef Server
```

Then add the cookbook to your node's run list:

```ruby
run_list 'recipe[k8s-worker]'
```

### Joining the Cluster

After `chef-client` completes, run the join command from the master node:

```bash
# On the master, generate a join command
kubeadm token create --print-join-command

# On the worker, run the output from above
kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash <HASH>
```

### Override Attributes

```ruby
default_attributes(
  'kubernetes' => {
    'version' => '1.31'
  }
)
```

## Author

Abhishek Ranjan
