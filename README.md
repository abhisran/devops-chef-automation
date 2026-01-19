# 🍳 Chef Cookbooks for Kubernetes Automation

Automated Kubernetes cluster deployment using Chef. These cookbooks handle everything from container runtime setup to cluster initialization—just upload and run.

Perfect for: Quickly spinning up production-ready K8s clusters with consistent configuration across all nodes.

---

## 📁 What's Inside

```
cookbooks/
├── kubernetes/
│   ├── k8s-master/    # Master node: containerd, kubeadm, kubelet, Flannel CNI
│   └── k8s-worker/    # Worker nodes: containerd, kubeadm, kubelet
└── system/
    ├── apt/           # APT package management with caching
    └── package/       # Package installation automation
```

---

## 📋 Prerequisites

### On Your Workstation:

```bash
# Install Chef Workstation
wget https://packages.chef.io/files/stable/chef-workstation/latest/ubuntu/22.04/chef-workstation_amd64.deb
sudo dpkg -i chef-workstation_amd64.deb

# Verify installation
chef --version
knife --version
```

### On target nodes:

- Ubuntu 18.04+ or Debian 9+
- SSH access with sudo privileges
- Chef Infra Client will be installed automatically during bootstrap

### Optional: Chef Server Setup

- Use [Hosted Chef](https://manage.chef.io/) (free for up to 5 nodes)
- Or install Chef Server locally
- Configure `knife.rb` with your Chef Server URL and credentials

---

## 🚀 Usage

### Option 1: With Chef Server (Recommended)

```bash
# 1. Upload cookbooks to Chef Server
knife cookbook upload apt package -o cookbooks/system/
knife cookbook upload k8s-master k8s-worker -o cookbooks/kubernetes/

# 2. Bootstrap master node (installs Chef Client + applies cookbooks)
knife bootstrap <MASTER_IP> --node-name k8s-master-01 \
  --run-list 'recipe[apt],recipe[package],recipe[k8s-master]' \
  --ssh-user ubuntu --sudo

# 3. Bootstrap worker nodes
knife bootstrap <WORKER_IP> --node-name k8s-worker-01 \
  --run-list 'recipe[apt],recipe[package],recipe[k8s-worker]' \
  --ssh-user ubuntu --sudo

# 4. Later, to apply updates
knife ssh 'name:k8s-*' 'sudo chef-client' --ssh-user ubuntu
```

### Option 2: Without Chef Server (Chef Zero/Local Mode)

```bash
# 1. Copy cookbooks to target node
scp -r cookbooks/ ubuntu@<NODE_IP>:/tmp/

# 2. SSH into node
ssh ubuntu@<NODE_IP>

# 3. Install Chef Infra Client
curl -L https://omnitruck.chef.io/install.sh | sudo bash

# 4. Run chef-client locally (for master node)
sudo chef-client -z \
  -o 'recipe[apt],recipe[package],recipe[k8s-master]' \
  --cookbook-path /tmp/cookbooks/system:/tmp/cookbooks/kubernetes

# For worker node, use: -o 'recipe[apt],recipe[package],recipe[k8s-worker]'
```

---

## 🔧 Tech Stack

- **Config Management**: Chef Infra
- **Container Runtime**: containerd  
- **K8s Bootstrap**: kubeadm
- **Networking**: Flannel CNI
- **OS Support**: Ubuntu 18.04+, Debian 9+

---

## 💡 Quick Tips

**Check if Chef Server has your cookbooks:**
```bash
knife cookbook list
```

**See node's current run-list:**
```bash
knife node show k8s-master-01 -a run_list
```

**Update a node's run-list:**
```bash
knife node run_list set k8s-worker-01 'recipe[apt],recipe[k8s-worker]'
```

**Verify cluster after setup:**
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

*This is a cookbooks-only repo. For a full Chef repository structure with roles, environments, and data bags, check out the [Chef Repo documentation](https://docs.chef.io/chef_repo/).*
