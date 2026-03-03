#
# Cookbook:: k8s-master
# Recipe:: kube_state_metrics
#
# Deploys kube-state-metrics into the Kubernetes cluster.
# KSM generates Prometheus-format metrics about the state of K8s objects
# (pods, deployments, nodes, jobs, etc.) by watching the API server.
#
# Exposed via NodePort so external Prometheus can scrape it.
#

return unless node['kubernetes']['kube_state_metrics']['enabled']

ksm_config = node['kubernetes']['kube_state_metrics']
ksm_manifest = '/etc/kubernetes/kube-state-metrics.yaml'

template ksm_manifest do
  source 'kube_state_metrics.yaml.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables(
    version: ksm_config['version'],
    namespace: ksm_config['namespace'],
    nodeport: ksm_config['nodeport'],
    image: ksm_config['image']
  )
end

execute 'apply-kube-state-metrics' do
  command "kubectl apply -f #{ksm_manifest}"
  action :run
  retries 3
  retry_delay 10
  only_if 'kubectl get --raw /readyz 2>/dev/null'
  only_if { ::File.exist?('/root/.kube/config') && ::File.exist?(ksm_manifest) }
end
