# 🍳 Chef Infrastructure Automation

Automated infrastructure deployment using Chef — Kubernetes clusters, Jenkins CI/CD, Nagios monitoring, and system configuration. Upload the cookbooks, assign run lists, and run `chef-client` to provision fully configured nodes.

> **📌 Project Evolution:** This project started as a Kubernetes-only automation toolkit. It has since grown into a complete infrastructure-as-code solution covering CI/CD (Jenkins), monitoring (Nagios), secrets management (Chef Vault), and system configuration — all driven by attributes with no hardcoded values.

---

## 📁 What's Inside

```
cookbooks/
├── grafana/
│   └── grafana-server/    # Grafana OSS: Prometheus datasource, dashboard provisioning
├── jenkins/
│   ├── jenkins-server/    # Controller: JCasC, 30+ plugins, Vault SSH credentials
│   └── jenkins-agent/     # Agent: Docker CE, kubectl, kubeconfig from Vault
├── kubernetes/
│   ├── k8s-master/        # Master: kubeadm init, Weave CNI, Jenkins RBAC
│   └── k8s-worker/        # Worker: containerd, kubelet, ready to join
├── nagios/
│   ├── nagios-server/     # Nagios Core from source, host/service auto-config
│   └── nagios-client/     # NRPE client: system + K8s + Jenkins checks
├── prometheus/
│   ├── prometheus-server/ # Prometheus: scrape configs, alert rules, TSDB
│   └── prometheus-client/ # Node Exporter: system metrics for all nodes
└── system/
    ├── apt/               # APT cache management & unattended upgrades
    ├── firewall/          # UFW firewall: role-based port rules, K8s forwarding
    └── package/           # Essential system packages (curl, git, conntrack, etc.)
```

> 📖 Each cookbook has its own detailed README inside `cookbooks/`.

---

## 📋 Prerequisites

### On Your Workstation:

```bash
# Install Chef Workstation (includes Berkshelf, knife, etc.)
wget https://packages.chef.io/files/stable/chef-workstation/latest/ubuntu/22.04/chef-workstation_amd64.deb
sudo dpkg -i chef-workstation_amd64.deb

# Verify installation
chef --version
knife --version
berks --version
```

### On Target Nodes:

- Ubuntu 18.04+ or Debian 9+
- SSH access with sudo privileges
- Chef Infra Client installed (via `knife bootstrap` or manually)

### Optional: Chef Server Setup

- Use [Hosted Chef](https://manage.chef.io/) (free for up to 5 nodes)
- Or install Chef Server locally
- Configure `knife.rb` with your Chef Server URL and credentials

---

## 🚀 Usage

### Option 1: With Chef Server (Recommended)

#### 1. Upload cookbooks using Berkshelf

```bash
cd cookbooks/system/apt && berks install && berks upload && cd -
cd cookbooks/system/package && berks install && berks upload && cd -
cd cookbooks/system/firewall && berks install && berks upload && cd -
cd cookbooks/kubernetes/k8s-master && berks install && berks upload && cd -
cd cookbooks/kubernetes/k8s-worker && berks install && berks upload && cd -
cd cookbooks/jenkins/jenkins-server && berks install && berks upload && cd -
cd cookbooks/jenkins/jenkins-agent && berks install && berks upload && cd -
cd cookbooks/nagios/nagios-server && berks install && berks upload && cd -
cd cookbooks/nagios/nagios-client && berks install && berks upload && cd -
cd cookbooks/prometheus/prometheus-server && berks install && berks upload && cd -
cd cookbooks/prometheus/prometheus-client && berks install && berks upload && cd -
cd cookbooks/grafana/grafana-server && berks install && berks upload && cd -
```

> `berks install` resolves and downloads cookbook dependencies.
> `berks upload` uploads the cookbook and its dependencies to the Chef Server.

#### 2. Assign cookbooks to nodes

```bash
# Kubernetes
knife node run_list add <K8S_MASTER_NODE> 'recipe[apt],recipe[package],recipe[k8s-master]'
knife node run_list add <K8S_WORKER_NODE> 'recipe[apt],recipe[package],recipe[k8s-worker]'

# Jenkins
knife node run_list add <JENKINS_SERVER_NODE> 'recipe[apt],recipe[package],recipe[jenkins-server]'
knife node run_list add <JENKINS_AGENT_NODE> 'recipe[apt],recipe[package],recipe[jenkins-agent]'

# Nagios
knife node run_list add <NAGIOS_SERVER_NODE> 'recipe[apt],recipe[package],recipe[nagios-server]'
knife node run_list add <NAGIOS_CLIENT_NODE> 'recipe[apt],recipe[package],recipe[nagios-client]'

# Prometheus
knife node run_list add <PROMETHEUS_SERVER_NODE> 'recipe[apt],recipe[package],recipe[prometheus-server]'
knife node run_list add <PROMETHEUS_CLIENT_NODE> 'recipe[apt],recipe[package],recipe[prometheus-client]'

# Grafana
knife node run_list add <GRAFANA_SERVER_NODE> 'recipe[apt],recipe[package],recipe[grafana-server]'
```

#### 3. Apply on target nodes

```bash
sudo chef-client
```

Or run remotely from your workstation:

```bash
knife ssh 'name:k8s-*' 'sudo chef-client' --ssh-user <SSH_USER>
knife ssh 'name:jenkins-*' 'sudo chef-client' --ssh-user <SSH_USER>
knife ssh 'name:nagios-*' 'sudo chef-client' --ssh-user <SSH_USER>
knife ssh 'name:prom-*' 'sudo chef-client' --ssh-user <SSH_USER>
knife ssh 'name:grafana-*' 'sudo chef-client' --ssh-user <SSH_USER>
```

### Option 2: Without Chef Server (Chef Zero/Local Mode)

```bash
# 1. Copy cookbooks to target node
scp -r cookbooks/ <SSH_USER>@<NODE_IP>:/tmp/

# 2. SSH into node
ssh <SSH_USER>@<NODE_IP>

# 3. Install Chef Infra Client
curl -L https://omnitruck.chef.io/install.sh | sudo bash

# 4. Run chef-client locally (example: master node)
sudo chef-client -z \
  -o 'recipe[apt],recipe[package],recipe[k8s-master]' \
  --cookbook-path /tmp/cookbooks/system:/tmp/cookbooks/kubernetes
```

---

## 🔧 Tech Stack

| Category | Technologies |
|----------|-------------|
| **Configuration Management** | Chef Infra, Chef Vault, Berkshelf |
| **Container Orchestration** | Kubernetes 1.33, kubeadm, containerd, Weave CNI |
| **CI/CD** | Jenkins, JCasC, jenkins-plugin-manager, Docker CE, kubectl |
| **Monitoring** | Nagios Core 4.5.11, NRPE 4.1.0, Prometheus 2.53.3, Node Exporter 1.8.2 |
| **Visualization** | Grafana OSS 12.x, Prometheus datasource, dashboard provisioning |
| **Security** | UFW firewall (role-based), Chef Vault (encrypted data bags), K8s RBAC, namespace isolation |
| **Platform** | Ubuntu/Debian, systemd, Apache (Nagios UI) |

---

## 💡 Quick Tips

**Check if Chef Server has your cookbooks:**
```bash
knife cookbook list
```

**See a node's current run-list:**
```bash
knife node show <NODE> -a run_list
```

**Add recipes to a node's run-list:**
```bash
knife node run_list add <NODE> 'recipe[apt],recipe[package],recipe[jenkins-agent]'
```

**Verify Kubernetes cluster after setup:**
```bash
kubectl get nodes
```

---

## 👤 Author

**Abhishek Ranjan** • DevOps Engineer
📧 abhisran6@gmail.com
💼 [LinkedIn](https://linkedin.com/in/abhishek-ranjan-4b95a0155)
🐙 [GitHub](https://github.com/abhisran)

---
