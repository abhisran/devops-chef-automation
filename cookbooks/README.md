# 🍳 Chef Cookbooks Collection

Infrastructure automation cookbooks for Kubernetes clusters, Jenkins CI/CD, Nagios monitoring, and system configuration.

---

## 📁 Structure

```
├── jenkins/
│   ├── jenkins-server/  → Jenkins controller (install, plugins, JCasC, SSH credentials)
│   └── jenkins-agent/   → Jenkins SSH agent (Docker, kubectl, vault-managed keys)
├── kubernetes/
│   ├── k8s-master/      → Master node setup (containerd, kubeadm, kubelet, Weave CNI, RBAC)
│   └── k8s-worker/      → Worker node setup (containerd, kubeadm, kubelet)
├── nagios/
│   ├── nagios-server/   → Nagios Core server (compile from source, host/service config)
│   └── nagios-client/   → NRPE client (system, K8s, and Jenkins checks)
└── system/
    ├── apt/             → APT package management & caching
    └── package/         → General package installation
```

---

## ⚡ Quick Start

### 1️⃣ Upload cookbooks to Chef Server
```bash
knife cookbook upload apt package -o system/
knife cookbook upload k8s-master k8s-worker -o kubernetes/
knife cookbook upload jenkins-server jenkins-agent -o jenkins/
knife cookbook upload nagios-server nagios-client -o nagios/
```

### 2️⃣ Bootstrap nodes
```bash
# Kubernetes master node
knife bootstrap <MASTER_IP> --node-name k8s-master-01 \
  --run-list 'recipe[apt],recipe[package],recipe[k8s-master]' --ssh-user ubuntu --sudo

# Kubernetes worker node
knife bootstrap <WORKER_IP> --node-name k8s-worker-01 \
  --run-list 'recipe[apt],recipe[package],recipe[k8s-worker]' --ssh-user ubuntu --sudo

# Jenkins server
knife bootstrap <JENKINS_IP> --node-name jenkins-server-01 \
  --run-list 'recipe[apt],recipe[package],recipe[jenkins-server]' --ssh-user ubuntu --sudo

# Jenkins agent
knife bootstrap <AGENT_IP> --node-name jenkins-agent-01 \
  --run-list 'recipe[apt],recipe[package],recipe[jenkins-agent]' --ssh-user ubuntu --sudo

# Nagios server
knife bootstrap <NAGIOS_IP> --node-name nagios-server-01 \
  --run-list 'recipe[apt],recipe[package],recipe[nagios-server]' --ssh-user ubuntu --sudo

# Nagios client (on any monitored node)
knife bootstrap <NODE_IP> --node-name monitored-node-01 \
  --run-list 'recipe[apt],recipe[package],recipe[nagios-client]' --ssh-user ubuntu --sudo
```

### 3️⃣ Apply updates (when needed)
```bash
knife ssh 'name:k8s-*' 'sudo chef-client' --ssh-user ubuntu
knife ssh 'name:jenkins-*' 'sudo chef-client' --ssh-user ubuntu
knife ssh 'name:nagios-*' 'sudo chef-client' --ssh-user ubuntu
```

---

## 🖥️ How Chef Works

```
 WORKSTATION              CHEF SERVER              TARGET NODES
┌───────────┐            ┌───────────┐            ┌───────────┐
│ cookbooks │  upload    │  stores   │   pull    │  k8s-master│
│ knife     │ ─────────► │ cookbooks │ ◄──────── │  k8s-worker│
└───────────┘            │ run lists │            │  jenkins   │
                         └───────────┘            │  nagios    │
                                                  └───────────┘
```

| Run On | Commands |
|--------|----------|
| 🖥️ Workstation | `knife cookbook upload`, `knife bootstrap`, `knife node run_list` |
| 🎯 Target Nodes | `chef-client` |

> **💡 Run lists** (which cookbook runs on which node) are configured on **Chef Server**, not in cookbooks.

---

## 📋 Assigning Cookbooks to Nodes

| Node Type | Cookbooks | Command |
|-----------|-----------|--------|
| **K8s Master** | apt, package, k8s-master | `knife node run_list set k8s-master-01 'recipe[apt],recipe[package],recipe[k8s-master]'` |
| **K8s Worker** | apt, package, k8s-worker | `knife node run_list set k8s-worker-01 'recipe[apt],recipe[package],recipe[k8s-worker]'` |
| **Jenkins Server** | apt, package, jenkins-server | `knife node run_list set jenkins-server-01 'recipe[apt],recipe[package],recipe[jenkins-server]'` |
| **Jenkins Agent** | apt, package, jenkins-agent | `knife node run_list set jenkins-agent-01 'recipe[apt],recipe[package],recipe[jenkins-agent]'` |
| **Nagios Server** | apt, package, nagios-server | `knife node run_list set nagios-server-01 'recipe[apt],recipe[package],recipe[nagios-server]'` |
| **Monitored Node** | apt, package, nagios-client | `knife node run_list set node-01 'recipe[apt],recipe[package],recipe[nagios-client]'` |
| **Any Node** | apt, package | `knife node run_list set node-01 'recipe[apt],recipe[package]'` |

---

## 🛠️ Without Chef Server (Chef Solo)

```bash
# On target node directly
sudo chef-solo -c solo.rb -j node.json
```

<details>
<summary>See solo.rb example</summary>

```ruby
cookbook_path ["/path/to/kubernetes", "/path/to/system", "/path/to/jenkins", "/path/to/nagios"]
```
</details>

---

## 📋 Requirements

- Chef Workstation on your machine
- Chef Infra Client >= 16.0 on nodes
- Ubuntu 18.04+ / Debian 9+

---

## 👤 Author

**Abhishek Ranjan** • abhisran6@gmail.com

---
