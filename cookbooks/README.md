# 🍳 Chef Cookbooks — Homelab Infrastructure as Code

A collection of **12 Chef cookbooks** that fully automate the provisioning, configuration, and monitoring of a production-style homelab environment — Kubernetes cluster, Jenkins CI/CD pipeline, and Nagios monitoring — all managed as code.

> **📌 Project Evolution:** This project started as a single Kubernetes cookbook for automating cluster provisioning. It has since grown into a complete infrastructure-as-code solution covering CI/CD (Jenkins), monitoring (Nagios), and system configuration — demonstrating how incremental automation compounds into a fully managed environment.

---

## ✨ Key Features

- **Kubernetes 1.32** cluster provisioning (master + workers) with containerd, Weave CNI, and CI/CD RBAC
- **Jenkins CI/CD** server with Configuration as Code (JCasC), 30+ plugins, and SSH-based agents with Docker & kubectl
- **Nagios Core** compiled from source with **30+ monitoring checks** across system, Kubernetes, and Jenkins
- **Prometheus** time-series monitoring with Node Exporter on all nodes and configurable alert rules
- **UFW firewall** on every node with role-based port rules, source restrictions, and K8s-aware forwarding
- **Chef Vault** integration for secrets management (SSH keys, kubeconfig) — no plaintext credentials
- **Fully idempotent** — every cookbook can be re-applied safely via `chef-client`
- **Attribute-driven** — all configurations are customizable through Chef roles/environments; no hardcoded values

---

## 🏗️ Infrastructure Architecture

```
                          ┌─────────────────────┐
                          │    Chef Server       │
                          └──────────┬──────────┘
                   cookbooks + vault │
          ┌──────────────┬───────────┼───────────┬──────────────┐
          ▼              ▼           ▼           ▼              ▼
  ┌──────────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐
  │  K8s Master  │ │ K8s       │ │ K8s       │ │  Jenkins  │ │  Jenkins  │
  │              │ │ Worker #1 │ │ Worker #2 │ │  Server   │ │  Agent    │
  │              │ │           │ │           │ │           │ │           │
  │ kubeadm      │ │ kubelet   │ │ kubelet   │ │ JCasC     │ │ Docker CE │
  │ etcd         │ │ containerd│ │ containerd│ │ 30+ plugs │ │ kubectl   │
  │ Weave CNI    │ │ kube-proxy│ │ kube-proxy│ │ Vault SSH │ │ kubeconfig│
  │ RBAC         │ └───────────┘ └───────────┘ └───────────┘ └───────────┘
  └──────────────┘
          ▲              ▲           ▲           ▲              ▲
          └──────────────┴───────────┼───────────┴──────────────┘
                                     │
                          ┌──────────┴──────────┐
                          │   Nagios Server      │
                          │   NRPE → 30+ checks  │
                          └─────────────────────┘
                          ┌──────────┬──────────┐
                          │  Prometheus Server   │
                          │  ← node_exporter     │
                          └─────────────────────┘
```

> All IPs, hostnames, and credentials are **configurable via Chef attributes** — override them in a role or environment to match your network.

---

## 🛠️ Tech Stack

| Category | Technologies |
|----------|-------------|
| **Configuration Management** | Chef Infra, Chef Vault, Berkshelf |
| **Container Orchestration** | Kubernetes 1.32, kubeadm, containerd, Weave CNI |
| **CI/CD** | Jenkins, JCasC, jenkins-plugin-manager, Docker CE, kubectl |
| **Monitoring** | Nagios Core 4.5.11, NRPE 4.1.0, Prometheus 2.53.3, Node Exporter 1.8.2 |
| **Security** | UFW firewall (role-based), Chef Vault (encrypted data bags), K8s RBAC, namespace isolation |
| **Platform** | Ubuntu/Debian, systemd, Apache (Nagios UI) |

---

## 📁 Cookbook Structure

```
├── grafana/
│   └── grafana-server/  → Grafana OSS: Prometheus datasource, dashboard provisioning
├── jenkins/
│   ├── jenkins-server/  → Controller: JCasC, 30+ plugins, Vault SSH credentials
│   └── jenkins-agent/   → Agent: Docker CE, kubectl, kubeconfig from Vault
├── kubernetes/
│   ├── k8s-master/      → Master: kubeadm init, Weave CNI, Jenkins RBAC
│   └── k8s-worker/      → Worker: containerd, kubelet, ready to join
├── nagios/
│   ├── nagios-server/   → Nagios Core from source, host/service auto-config
│   └── nagios-client/   → NRPE client: system + K8s + Jenkins checks
├── prometheus/
│   ├── prometheus-server/ → Prometheus server: scrape configs, alert rules, TSDB
│   └── prometheus-client/ → Node Exporter: system metrics for all nodes
└── system/
    ├── apt/             → APT cache management & unattended upgrades
    ├── firewall/        → UFW firewall: role-based port rules, K8s forwarding
    └── package/         → Essential system packages (curl, git, conntrack, etc.)
```

> 📖 Each cookbook has its own detailed README — see links in the [Cookbooks](#-cookbooks) section below.

---

## 📦 Cookbooks

### [grafana-server](grafana/grafana-server/)
Installs Grafana OSS via the official APT repository with attribute-driven configuration. Deploys `grafana.ini` with sensible defaults, provisions **Prometheus as a default datasource**, and sets up file-based dashboard provisioning from `/var/lib/grafana/dashboards`. Uses **Unified Alerting** (Grafana 12+ removed legacy alerting). Includes UFW firewall rules for port 3000.

### [jenkins-server](jenkins/jenkins-server/)
Installs Jenkins with OpenJDK 21, deploys 30+ plugins via the official plugin manager CLI, and configures the server entirely through **Jenkins Configuration as Code (JCasC)**. Agent nodes are auto-registered via SSH using credentials stored in **Chef Vault** — zero manual setup in the Jenkins UI.

### [jenkins-agent](jenkins/jenkins-agent/)
Prepares SSH-based build agents with **Docker CE** (docker build/push from pipelines), **kubectl** with a vault-managed kubeconfig (deploy to staging/production contexts), and all required build tools.

### [k8s-master](kubernetes/k8s-master/)
Bootstraps the Kubernetes control plane with `kubeadm init`, installs the **Weave** network plugin, and creates **RBAC resources** for Jenkins CI/CD — a `jenkins-deployer` ServiceAccount with namespace-scoped Roles in `staging` and `production`.

### [k8s-worker](kubernetes/k8s-worker/)
Installs **containerd** (with SystemdCgroup), kubeadm, and kubelet. Prepares the node to join the cluster via `kubeadm join`.

### [nagios-server](nagios/nagios-server/)
Compiles **Nagios Core 4.5.11** from source with the NRPE plugin. Auto-generates host, hostgroup, and service configurations from node attributes — adding a new monitored host is a single attribute override.

### [nagios-client](nagios/nagios-client/)
Installs the NRPE daemon and deploys **30+ check commands** covering system health, Kubernetes components (process + health endpoint checks), and Jenkins infrastructure.

### [prometheus-server](prometheus/prometheus-server/)
Installs **Prometheus 2.53.3** from official releases with attribute-driven scrape configs, alert rules (InstanceDown, HighCPU, HighMemory, DiskSpaceLow), and optional Alertmanager integration. Configuration is validated with `promtool` on every change.

### [prometheus-client](prometheus/prometheus-client/)
Installs **Node Exporter 1.8.2** on all monitored nodes, exposing system metrics (CPU, memory, disk, network) for Prometheus scraping. Includes textfile and systemd collectors by default.

### [firewall](system/firewall/)
Installs **UFW** on every node with attribute-driven rule groups per role. Default deny incoming with per-service port allowlists, source-restricted monitoring ports (NRPE, Node Exporter), and automatic IP forwarding + FORWARD policy for Kubernetes nodes.

### [apt](system/apt/) · [package](system/package/)
System-level cookbooks for APT cache management and essential package installation.

---

## 📊 Monitoring Overview

Nagios monitors every node with checks organized by hostgroup:

| Hostgroup | Checks |
|-----------|--------|
| **All Servers** | Disk, Memory, Load, Processes, Zombies, SSH, Users |
| **K8s Cluster** | Kubelet, Containerd, Kube-Proxy (process + health), CoreDNS, Containerd Socket |
| **K8s Masters** | API Server, etcd, Scheduler, Controller Manager (process + `/healthz` endpoints) |
| **Jenkins Server** | Jenkins Process, Web UI (HTTP 200), Swap |
| **Jenkins Agent** | Jenkins User, Work Directory, Swap |
| **Infrastructure** | HTTP, Swap |

---

## ⚡ Quick Start

For the full setup workflow — uploading cookbooks with Berkshelf, bootstrapping nodes, and applying updates — see the [main README](../README.md#-usage).

---

## 🔧 Customization

All cookbooks are **attribute-driven** — no source code changes are needed to adapt them to your environment. Override attributes in a Chef role, environment, or wrapper cookbook.

Common overrides:

```ruby
# Example Chef role (my_infra.rb)
name 'my_infra'
default_attributes(
  'jenkins' => {
    'casc' => { 'jenkins_url' => 'http://jenkins.example.com:8080/' },
    'agents' => [
      { 'name' => 'agent-01', 'host' => '10.0.0.20', 'label' => 'linux docker',
        'executors' => 2, 'work_dir' => '/var/lib/jenkins/agent',
        'java_path' => '/usr/bin/java', 'description' => 'Build agent 01' }
    ]
  },
  'nagios' => {
    'server' => { 'ip' => '10.0.0.30' },
    'admin_password' => 'your_secure_password',
    'monitored_hosts' => [
      { 'host_name' => 'web-01', 'alias' => 'Web Server',
        'address' => '10.0.0.40', 'hostgroups' => %w(monitored-servers infrastructure-servers) }
    ]
  },
  'kubernetes' => {
    'version' => '1.32'
  }
)
```

See each cookbook's README for the full list of configurable attributes.

---

## 📋 Requirements

- Chef Workstation on your machine
- Chef Infra Client >= 16.0 on nodes
- Ubuntu 18.04+ / Debian 9+

---
