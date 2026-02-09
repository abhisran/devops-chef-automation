#
# Cookbook:: k8s-master
# Recipe:: rbac
#
# Copyright:: 2025, The Authors, All Rights Reserved.

return unless node['kubernetes']['rbac']['jenkins']['enabled']

rbac_manifest = '/etc/kubernetes/jenkins-rbac.yaml'

template rbac_manifest do
  source 'jenkins_rbac.yaml.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables(
    sa_name: node['kubernetes']['rbac']['jenkins']['service_account'],
    sa_namespace: node['kubernetes']['rbac']['jenkins']['namespace'],
    deploy_namespaces: node['kubernetes']['rbac']['jenkins']['deploy_namespaces']
  )
end

execute 'apply-jenkins-rbac' do
  command "kubectl apply -f #{rbac_manifest}"
  action :run
  only_if { ::File.exist?('/root/.kube/config') && ::File.exist?(rbac_manifest) }
end
