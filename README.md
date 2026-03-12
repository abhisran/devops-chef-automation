# 🍳 Chef Infrastructure Automation

Automated, attribute-driven infrastructure deployment using Chef Infra — managing Kubernetes clusters, Jenkins CI/CD pipelines, Nagios monitoring, and distributed storage.

> **🚀 Project Impact:** This project serves as a complete Infrastructure-as-Code (IaC) blueprint. It automates the lifecycle of a hybrid devops environment — from base OS hardening and firewall configuration to complex application orchestration like Kubernetes and JCasC-driven Jenkins.

---

## 🌟 Key Features

- **End-to-End Automation:** Provisioning of a full DevOps stack (K8s, CI/CD, Monitoring, Storage) from a single command.
- **Zero Hardcoding:** 100% attribute-driven configuration; environment-specific values are injected via Chef Roles/Environments.
- **Secrets Management:** Integrated **Chef Vault** for secure handling of SSH keys, Kubeconfigs, and credentials.
- **Infrastructure Observability:** Auto-configuring Nagios (NRPE) and Prometheus (Node Exporter) targets for every new node.
- **Cloud-Native Ready:** Kubernetes 1.33 cluster automation with containerd, Weave CNI, and automated RBAC for CI/CD.
- **CI/CD as Code:** Jenkins controller fully configured via **JCasC (Jenkins Configuration as Code)**, including 30+ plugins and automated agent registration.

---

## 🏗️ Architecture Overview

1.  **Workstation:** Cookbooks are developed and managed via **Berkshelf**.
2.  **Chef Server:** Acts as the central hub for cookbooks, node attributes, and data bags.
3.  **Nodes:** Run `chef-client` to pull desired state and apply configurations.
4.  **Security Layer:** **UFW** manages role-specific firewall rules; **Chef Vault** handles encrypted data.

---

## 📁 Project Structure

```bash
cookbooks/
├── kubernetes/        # K8s 1.33: kubeadm, containerd, Weave CNI, RBAC
├── jenkins/           # CI/CD: JCasC, OpenJDK 21, Docker Agents, kubectl
├── nagios/            # Monitoring: Nagios Core 4.5.11 (source), NRPE 4.1.0
├── prometheus/        # Metrics: Prometheus 2.53.3, Node Exporter 1.8.2
├── grafana/           # Visualization: Grafana 12.x, Unified Alerting
├── nfs/               # Storage: Kernel-based NFS Server/Client
└── system/            # Core: UFW Firewall, APT management, Base Packages
```

---

## 🔧 Tech Stack

| Category | Technologies |
|----------|-------------|
| **Config Management** | Chef Infra 18+, Berkshelf, Chef Vault, Data Bags |
| **Orchestration** | Kubernetes 1.33, kubeadm, containerd, Weave CNI |
| **CI/CD** | Jenkins (LTS), JCasC, Docker CE, kubectl |
| **Monitoring** | Nagios Core 4.5.11, Prometheus 2.53.3, Node Exporter 1.8.2 |
| **Visualization** | Grafana OSS 12.x, Unified Alerting |
| **Storage & Security** | NFS (Kernel), UFW Firewall, RBAC, SSL/TLS |
| **OS/Platform** | Ubuntu 22.04 LTS, Debian 12, systemd, Apache2 |

---

## 🚀 Quick Start

### 1. Upload the Stack

```bash
# Upload core system and applications
for cb in system/apt system/package system/firewall kubernetes/k8s-master \
          kubernetes/k8s-worker jenkins/jenkins-server jenkins/jenkins-agent \
          nagios/nagios-server nagios/nagios-client prometheus/prometheus-server \
          prometheus/prometheus-client grafana/grafana-server nfs/nfs-server; do
    cd cookbooks/$cb && berks install && berks upload && cd -
done
```

### 2. Provision Nodes

```bash
# Example: Deploying a Kubernetes Master
knife node run_list add k8s-master 'recipe[apt],recipe[package],recipe[k8s-master]'
ssh k8s-master 'sudo chef-client'

# Example: Deploying Jenkins Controller
knife node run_list add jenkins-server 'recipe[apt],recipe[package],recipe[jenkins-server]'
ssh jenkins-server 'sudo chef-client'
```

---

## 💡 Engineering Standards

- **Idempotency:** Every recipe is tested to ensure multiple runs do not change the system state unless configuration changes.
- **Modularity:** Separation of concerns between `install`, `config`, and `service` recipes within cookbooks.
- **Validation:** Automatic configuration validation (e.g., `promtool` for Prometheus, `nagios -v` for Nagios) before service restarts.

---

## 👤 Author

**Abhishek Ranjan** • DevOps Engineer
📧 [abhisran6@gmail.com](mailto:abhisran6@gmail.com)
💼 [LinkedIn](https://linkedin.com/in/abhishek-ranjan-4b95a0155)
🐙 [GitHub](https://github.com/abhisran)

---
