#
# Cookbook:: k8s-master
# Recipe:: rbac
#
# Copyright:: 2025, The Authors, All Rights Reserved.

# --- Jenkins CI/CD RBAC ---
if node['kubernetes']['rbac']['jenkins']['enabled']
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
    retries 3
    retry_delay 10
    only_if 'kubectl get --raw /readyz 2>/dev/null'
    only_if { ::File.exist?('/root/.kube/config') && ::File.exist?(rbac_manifest) }
  end

  # Extract the long-lived token and generate a portable kubeconfig
  jenkins_token_output = '/etc/kubernetes/jenkins-token.txt'
  jenkins_kubeconfig_output = '/etc/kubernetes/jenkins.kubeconfig'
  sa_name = node['kubernetes']['rbac']['jenkins']['service_account']
  sa_namespace = node['kubernetes']['rbac']['jenkins']['namespace']
  
  # Get the API Server internal endpoint (usually the master's IP)
  api_server = "https://#{node['ipaddress']}:6443"

  execute 'generate-jenkins-kubeconfig' do
    command <<-EOH
      TOKEN=$(kubectl get secret #{sa_name}-token -n #{sa_namespace} \
        -o go-template='{{.data.token | base64decode}}' 2>/dev/null)
      
      if [ -n "$TOKEN" ]; then
        echo -n "$TOKEN" > #{jenkins_token_output}
        
        # Create a portable kubeconfig using the internal CA and the token
        kubectl config set-cluster homelab \
          --certificate-authority=/etc/kubernetes/pki/ca.crt \
          --embed-certs=true \
          --server=#{api_server} \
          --kubeconfig=#{jenkins_kubeconfig_output}
          
        kubectl config set-credentials #{sa_name} \
          --token="$TOKEN" \
          --kubeconfig=#{jenkins_kubeconfig_output}
          
        kubectl config set-context jenkins-context \
          --cluster=homelab \
          --user=#{sa_name} \
          --namespace=default \
          --kubeconfig=#{jenkins_kubeconfig_output}
          
        kubectl config use-context jenkins-context \
          --kubeconfig=#{jenkins_kubeconfig_output}
          
        chmod 600 #{jenkins_kubeconfig_output}
      fi
    EOH
    retries 3
    retry_delay 5
    only_if { ::File.exist?('/root/.kube/config') }
    # Only run if the token file is missing or the kubeconfig is missing
    not_if { ::File.exist?(jenkins_kubeconfig_output) }
  end

  file jenkins_token_output do
    owner 'root'
    group 'root'
    mode '0600'
  end
  
  file jenkins_kubeconfig_output do
    owner 'root'
    group 'root'
    mode '0600'
  end
end

# --- Prometheus monitoring RBAC ---
if node['kubernetes']['rbac']['prometheus']['enabled']
  prom_rbac_manifest = '/etc/kubernetes/prometheus-rbac.yaml'
  prom_sa_name = node['kubernetes']['rbac']['prometheus']['service_account']
  prom_namespace = node['kubernetes']['rbac']['prometheus']['namespace']
  token_output = node['kubernetes']['rbac']['prometheus']['token_output_path']

  template prom_rbac_manifest do
    source 'prometheus_rbac.yaml.erb'
    owner 'root'
    group 'root'
    mode '0600'
    variables(
      sa_name: prom_sa_name,
      sa_namespace: prom_namespace
    )
  end

  execute 'apply-prometheus-rbac' do
    command "kubectl apply -f #{prom_rbac_manifest}"
    action :run
    retries 3
    retry_delay 10
    only_if 'kubectl get --raw /readyz 2>/dev/null'
    only_if { ::File.exist?('/root/.kube/config') && ::File.exist?(prom_rbac_manifest) }
  end

  # Extract the long-lived token from the Secret so it can be copied to the
  # Prometheus server at /etc/prometheus/k8s_token.
  execute 'extract-prometheus-token' do
    command <<-EOH
      TOKEN=$(kubectl get secret #{prom_sa_name}-token -n #{prom_namespace} \
        -o go-template='{{.data.token | base64decode}}' 2>/dev/null) && \
      [ -n "$TOKEN" ] && \
      echo -n "$TOKEN" > #{token_output}
    EOH
    retries 3
    retry_delay 5
    only_if { ::File.exist?('/root/.kube/config') }
    not_if { ::File.exist?(token_output) && ::File.size(token_output) > 0 }
  end

  file token_output do
    owner 'root'
    group 'root'
    mode '0600'
    only_if { ::File.exist?(token_output) }
  end
end
