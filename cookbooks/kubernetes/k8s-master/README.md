# k8s-master

Chef cookbook to configure a Kubernetes master node with:

- Container runtime (containerd)
- Kubernetes components (kubeadm, kubelet, kubectl)
- Kubernetes master initialization
- Weave CNI plugin
- Jenkins CI/CD RBAC (ServiceAccount + namespace-scoped Roles)

## Requirements

### Platforms

- Debian/Ubuntu

### Chef

- Chef 16+

## Attributes

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['kubernetes']['version']` | Kubernetes version | `1.35` |
| `node['kubernetes']['packages']` | K8s packages to install | `kubelet kubeadm kubectl` |
| `node['kubernetes']['cni_version']` | CNI plugin version | `1.4.0` |
| `node['kubernetes']['network_plugin']['name']` | Network plugin name | `weave` |
| `node['kubernetes']['rbac']['jenkins']['enabled']` | Enable Jenkins RBAC setup | `true` |
| `node['kubernetes']['rbac']['jenkins']['service_account']` | ServiceAccount name for Jenkins | `jenkins-deployer` |
| `node['kubernetes']['rbac']['jenkins']['namespace']` | Namespace for the ServiceAccount | `ci-cd` |
| `node['kubernetes']['rbac']['jenkins']['deploy_namespaces']` | Namespaces Jenkins can deploy to | `ci-cd default staging production` |
| `node['kubernetes']['rbac']['prometheus']['enabled']` | Enable Prometheus RBAC setup | `true` |
| `node['kubernetes']['monitoring']['patch_manifests']` | Expose control plane metrics on 0.0.0.0 | `true` |
| `node['kubernetes']['kube_state_metrics']['enabled']` | Deploy kube-state-metrics to cluster | `true` |
| `node['kubernetes']['kube_state_metrics']['version']` | KSM version | `2.13.0` |
| `node['kubernetes']['kube_state_metrics']['nodeport']` | KSM NodePort for Prometheus scraping | `30080` |

## Recipes

### default

Includes all other recipes in the correct order.

### containerd

Installs and configures the containerd container runtime with SystemdCgroup support.

### kubernetes

Disables swap, adds the Kubernetes apt repository, and installs kubeadm, kubelet, and kubectl. Holds packages at the current version.

### master

Pulls required images, initializes the Kubernetes master with `kubeadm init`, configures kubectl for the root user, and installs the Weave network plugin.

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

### monitoring

Patches static pod manifests (`/etc/kubernetes/manifests/`) for `etcd`, `kube-scheduler`, and `kube-controller-manager` to expose their metrics endpoints on `0.0.0.0` instead of `127.0.0.1`, enabling external scraping by Prometheus. Kubelet automatically reloads the static pods when manifests change.

### kube_state_metrics

Deploys `kube-state-metrics` (v2.13.0) into the `kube-system` namespace. Exposes cluster-level object metrics (deployments, pods, nodes, jobs) via NodePort `30080` for Prometheus.

### RBAC Permissions

The `jenkins-deployer` Role grants the following permissions in each deploy namespace:

| API Group | Resources | Verbs |
|-----------|-----------|-------|
| `apps` | deployments, replicasets, statefulsets | get, list, watch, create, update, patch, delete |
| (core) | services, pods, configmaps, secrets, persistentvolumeclaims | get, list, watch, create, update, patch, delete |
| `networking.k8s.io` | ingresses | get, list, watch, create, update, patch, delete |
| `batch` | jobs, cronjobs | get, list, watch, create, update, patch, delete |

Jenkins **cannot** access `kube-system`, `default`, or any other namespace not listed in `deploy_namespaces`.

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
  '{"kubernetes":{"version":"1.35","cni_version":"1.4.0"}}' \
  --search "role:k8s-master OR role:k8s-worker" \
  --admins "admin_user"
```

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

## Author

Abhishek Ranjan
