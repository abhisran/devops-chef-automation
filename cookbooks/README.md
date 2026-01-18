# 🍳 Chef Cookbooks Collection

Infrastructure automation cookbooks for Kubernetes clusters and system configuration.

---

## 📁 Structure

```
├── kubernetes/
│   ├── k8s-master/    → Master node setup (containerd, kubeadm, kubelet, Flannel CNI)
│   └── k8s-worker/    → Worker node setup (containerd, kubeadm, kubelet)
└── system/
    ├── apt/           → APT package management & caching
    └── package/       → General package installation
```

---

## ⚡ Quick Start

### 1️⃣ Upload cookbooks to Chef Server
```bash
knife cookbook upload apt package -o system/
knife cookbook upload k8s-master k8s-worker -o kubernetes/
```

### 2️⃣ Bootstrap nodes
```bash
# Master node
knife bootstrap <MASTER_IP> --node-name k8s-master-01 \
  --run-list 'recipe[apt],recipe[k8s-master]' --ssh-user ubuntu --sudo

# Worker node
knife bootstrap <WORKER_IP> --node-name k8s-worker-01 \
  --run-list 'recipe[apt],recipe[k8s-worker]' --ssh-user ubuntu --sudo
```

### 3️⃣ Apply updates (when needed)
```bash
knife ssh 'name:k8s-*' 'sudo chef-client' --ssh-user ubuntu
```

---

## 🖥️ How Chef Works

```
 WORKSTATION              CHEF SERVER              TARGET NODES
┌───────────┐            ┌───────────┐            ┌───────────┐
│ cookbooks │  upload    │  stores   │   pull    │  k8s-master│
│ knife     │ ─────────► │ cookbooks │ ◄──────── │  k8s-worker│
└───────────┘            │ run lists │            └───────────┘
                         └───────────┘
```

| Run On | Commands |
|--------|----------|
| 🖥️ Workstation | `knife cookbook upload`, `knife bootstrap`, `knife node run_list` |
| 🎯 Target Nodes | `chef-client` |

> **💡 Run lists** (which cookbook runs on which node) are configured on **Chef Server**, not in cookbooks.

---

## 📋 Assigning Cookbooks to Nodes

| Node Type | Cookbook to Assign | Command |
|-----------|-------------------|--------|
| **Master** | `k8s-master` | `knife node run_list set k8s-master-01 'recipe[apt],recipe[k8s-master]'` |
| **Worker** | `k8s-worker` | `knife node run_list set k8s-worker-01 'recipe[apt],recipe[k8s-worker]'` |

---

## 🛠️ Without Chef Server (Chef Solo)

```bash
# On target node directly
sudo chef-solo -c solo.rb -j node.json
```

<details>
<summary>See solo.rb example</summary>

```ruby
cookbook_path ["/path/to/kubernetes", "/path/to/system"]
```
</details>

---

## 📋 Requirements

- Chef Workstation on your machine
- Chef Infra Client >= 16.0 on nodes
- Ubuntu 18.04+ / Debian 9+

---

## 👤 Author

**Abhishek Ranjan** • abhisran60@gmail.com

---

*More cookbooks coming soon: monitoring, databases, web-servers*
