#
# Cookbook:: k8s-master
# Recipe:: monitoring
#
# Patches kubeadm-managed static pod manifests to expose metrics endpoints
# on all interfaces (0.0.0.0) instead of localhost only (127.0.0.1).
# This allows external Prometheus to scrape control plane metrics.
#
# Components patched:
#   - etcd:                    --listen-metrics-urls  (port 2381)
#   - kube-scheduler:          --bind-address         (port 10259)
#   - kube-controller-manager: --bind-address         (port 10257)
#
# Kubelet automatically restarts the affected pods when manifests change.
#

return unless node['kubernetes']['monitoring']['patch_manifests']

manifests_dir = '/etc/kubernetes/manifests'

# etcd: expose metrics endpoint for external scraping
execute 'patch-etcd-metrics-bind' do
  command "sed -i 's|--listen-metrics-urls=http://127.0.0.1:2381|--listen-metrics-urls=http://0.0.0.0:2381|' #{manifests_dir}/etcd.yaml"
  only_if { ::File.exist?("#{manifests_dir}/etcd.yaml") }
  only_if "grep -q -- '--listen-metrics-urls=http://127.0.0.1:2381' #{manifests_dir}/etcd.yaml"
end

# kube-scheduler: expose metrics endpoint for external scraping
execute 'patch-kube-scheduler-bind' do
  command "sed -i 's|--bind-address=127.0.0.1|--bind-address=0.0.0.0|' #{manifests_dir}/kube-scheduler.yaml"
  only_if { ::File.exist?("#{manifests_dir}/kube-scheduler.yaml") }
  only_if "grep -q -- '--bind-address=127.0.0.1' #{manifests_dir}/kube-scheduler.yaml"
end

# kube-controller-manager: expose metrics endpoint for external scraping
execute 'patch-kube-controller-manager-bind' do
  command "sed -i 's|--bind-address=127.0.0.1|--bind-address=0.0.0.0|' #{manifests_dir}/kube-controller-manager.yaml"
  only_if { ::File.exist?("#{manifests_dir}/kube-controller-manager.yaml") }
  only_if "grep -q -- '--bind-address=127.0.0.1' #{manifests_dir}/kube-controller-manager.yaml"
end
