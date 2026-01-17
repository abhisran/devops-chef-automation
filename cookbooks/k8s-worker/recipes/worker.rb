#
# Cookbook:: k8s-worker
# Recipe:: worker
#
# Copyright:: 2025, The Authors, All Rights Reserved.

# NOTE: Before joining:
# 1. Install kubeadm: apt-get install -y kubeadm
# 2. Run the join command from master: kubeadm join <master-ip>:<master-port> --token <token> --discovery-token-ca-cert-hash <hash>
# 3. Optionally remove kubeadm after joining: apt-get remove kubeadm

log 'worker_join_message' do
  message 'Worker node is ready. Install kubeadm temporarily to join the cluster, then remove it.'
  level :info
end
