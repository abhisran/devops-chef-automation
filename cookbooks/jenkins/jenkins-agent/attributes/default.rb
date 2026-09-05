default['jenkins']['java_package'] = 'openjdk-21-jre'

default['jenkins']['agent']['user'] = 'jenkins'
default['jenkins']['agent']['group'] = 'jenkins'
default['jenkins']['agent']['home'] = '/var/lib/jenkins'
default['jenkins']['agent']['work_dir'] = '/var/lib/jenkins/agent'
default['jenkins']['agent']['build_packages'] = %w(git curl build-essential openssh-server)

default['jenkins']['vault']['name'] = 'jenkins_credentials'
default['jenkins']['vault']['item'] = 'ssh_keys'
default['jenkins']['vault']['kubeconfig_item'] = 'kubeconfig'

# Docker
default['jenkins']['agent']['docker']['enabled'] = true
default['jenkins']['agent']['docker']['packages'] = %w(
  docker-ce
  docker-ce-cli
  containerd.io
  docker-buildx-plugin
  docker-compose-plugin
)

# kubectl
default['jenkins']['agent']['kubectl']['enabled'] = true
default['jenkins']['agent']['kubectl']['k8s_version'] = '1.35'

# Terraform
default['jenkins']['agent']['terraform']['enabled'] = true
default['jenkins']['agent']['terraform']['version'] = nil

# Azure CLI
default['jenkins']['agent']['azure_cli']['enabled'] = true

# AWS CLI
default['jenkins']['agent']['aws_cli']['enabled'] = true

# Other build tools
default['jenkins']['agent']['jq']['enabled'] = true
default['jenkins']['agent']['ansible']['enabled'] = true
default['jenkins']['agent']['helm']['enabled'] = true
default['jenkins']['agent']['python']['enabled'] = true
default['jenkins']['agent']['maven']['enabled'] = true
