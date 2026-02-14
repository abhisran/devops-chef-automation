# jenkins-agent Cookbook

Installs and configures a Jenkins SSH agent (worker node). The Jenkins server connects to this node via SSH to run builds. Optionally installs Docker CE and kubectl for CI/CD pipelines that build container images and deploy to Kubernetes.

## Requirements

### Platforms

- Debian/Ubuntu

### Chef

- Chef 16+

### Dependencies

- `chef-vault` (~> 4.0)

## Chef Vault Setup

SSH credentials are managed via Chef Vault shared with the `jenkins-server` cookbook. See the [jenkins-server README](../jenkins-server/README.md#chef-vault-setup-one-time) for the one-time vault setup instructions.

The agent cookbook automatically reads the public key from the `jenkins_credentials/ssh_keys` vault and deploys it to `~/.ssh/authorized_keys`.

When adding a new agent node, refresh the vault so it can decrypt:

```bash
knife vault refresh jenkins_credentials ssh_keys \
  --search 'recipe:jenkins-server OR recipe:jenkins-agent'
```

## Kubeconfig Vault Setup

The kubeconfig for kubectl access to the Kubernetes cluster is stored in Chef Vault. This must be set up **after** the K8s RBAC resources are created on the master node (see [k8s-master RBAC setup](../../kubernetes/k8s-master/README.md)).

### 1. Extract the ServiceAccount token from K8s

Run these on your workstation (where kubectl is configured):

```bash
# Get the CA certificate
kubectl -n ci-cd get secret jenkins-deployer-token \
  -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/k8s-ca.crt

# Get the token
TOKEN=$(kubectl -n ci-cd get secret jenkins-deployer-token \
  -o jsonpath='{.data.token}' | base64 -d)

# Get the API server address (from your kubeconfig)
SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
```

### 2. Build the kubeconfig file

```bash
# Create kubeconfig with staging and production contexts
KUBECONFIG=/tmp/jenkins-kubeconfig kubectl config set-cluster homelab \
  --server="$SERVER" \
  --certificate-authority=/tmp/k8s-ca.crt \
  --embed-certs=true

KUBECONFIG=/tmp/jenkins-kubeconfig kubectl config set-credentials jenkins-deployer \
  --token="$TOKEN"

KUBECONFIG=/tmp/jenkins-kubeconfig kubectl config set-context staging \
  --cluster=homelab \
  --user=jenkins-deployer \
  --namespace=staging

KUBECONFIG=/tmp/jenkins-kubeconfig kubectl config set-context production \
  --cluster=homelab \
  --user=jenkins-deployer \
  --namespace=production

KUBECONFIG=/tmp/jenkins-kubeconfig kubectl config use-context staging
```

### 3. Store in Chef Vault

```bash
jq -n --arg kc "$(cat /tmp/jenkins-kubeconfig)" \
  '{"id":"kubeconfig","kubeconfig":$kc}' > /tmp/jenkins_kubeconfig.json

knife vault create jenkins_credentials kubeconfig \
  --json /tmp/jenkins_kubeconfig.json \
  --search 'recipe:jenkins-agent' \
  --admins '<CHEF_USERNAME>'

# Clean up
rm -f /tmp/jenkins-kubeconfig /tmp/jenkins_kubeconfig.json /tmp/k8s-ca.crt
```

### 4. Verify from a pipeline

After running `chef-client` on the agent, test:

```bash
sudo -u jenkins kubectl --context=staging get pods
sudo -u jenkins kubectl --context=production get pods
```

## Attributes

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['jenkins']['java_package']` | Java package to install | `openjdk-21-jre` |
| `node['jenkins']['agent']['user']` | Jenkins agent user | `jenkins` |
| `node['jenkins']['agent']['group']` | Jenkins agent group | `jenkins` |
| `node['jenkins']['agent']['home']` | Jenkins agent home directory | `/var/lib/jenkins` |
| `node['jenkins']['agent']['work_dir']` | Agent workspace/remoting directory | `/var/lib/jenkins/agent` |
| `node['jenkins']['agent']['build_packages']` | Build tools to install | `git curl build-essential openssh-server` |
| `node['jenkins']['agent']['docker']['enabled']` | Install Docker CE | `true` |
| `node['jenkins']['agent']['docker']['packages']` | Docker packages to install | `docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin` |
| `node['jenkins']['agent']['kubectl']['enabled']` | Install kubectl and deploy kubeconfig | `true` |
| `node['jenkins']['agent']['kubectl']['k8s_version']` | Kubernetes version for kubectl | `1.32` |
| `node['jenkins']['vault']['name']` | Chef Vault name for credentials | `jenkins_credentials` |
| `node['jenkins']['vault']['item']` | Chef Vault item for SSH keys | `ssh_keys` |
| `node['jenkins']['vault']['kubeconfig_item']` | Chef Vault item for kubeconfig | `kubeconfig` |

## Usage

### Install & Upload

```bash
cd jenkins/jenkins-agent
berks install    # resolves cookbook dependencies
berks upload     # uploads cookbook + dependencies to Chef Server
```

Then add the cookbook to your node's run list:

```ruby
run_list 'recipe[jenkins-agent]'
```

The SSH public key is automatically fetched from Chef Vault — no manual attribute overrides needed.

To disable Docker or kubectl installation:

```ruby
default_attributes(
  'jenkins' => {
    'agent' => {
      'docker' => { 'enabled' => false },
      'kubectl' => { 'enabled' => false }
    }
  }
)
```

## Recipes

### default

Includes all other recipes in the correct order.

### install

Installs Java (fontconfig + OpenJDK 21), creates the jenkins user and group, and installs build tools.

### config

Reads the SSH public key from Chef Vault and deploys it to `~/.ssh/authorized_keys` for SSH access from the Jenkins server. Creates the agent work directory.

### docker

Installs Docker CE from the official Docker apt repository. Adds the jenkins user to the `docker` group so pipelines can run `docker build`, `docker push`, etc. without sudo. Can be disabled via `node['jenkins']['agent']['docker']['enabled']`.

### kubectl

Installs kubectl from the official Kubernetes apt repository (matching the cluster version). Reads the kubeconfig from Chef Vault (`jenkins_credentials/kubeconfig`) and deploys it to `~/.kube/config`. Pipelines can then use `kubectl --context=staging` or `kubectl --context=production` to deploy. Can be disabled via `node['jenkins']['agent']['kubectl']['enabled']`.

### service

Ensures the SSH service is enabled and running, then logs that the agent is ready for connections from the Jenkins server.

## Author

Abhishek Ranjan
