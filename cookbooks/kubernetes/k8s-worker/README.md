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
| `node['kubernetes']['version']` | Kubernetes version | `1.32` |
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

## Usage

Add the cookbook to your node's run list:

```ruby
run_list 'recipe[k8s-worker]'
```

### Joining the Cluster

After `chef-client` completes, run the join command from the master node:

```bash
# On the master, generate a join command
kubeadm token create --print-join-command

# On the worker, run the output from above
kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
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
