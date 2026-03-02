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
default['jenkins']['agent']['kubectl']['k8s_version'] = '1.33'
