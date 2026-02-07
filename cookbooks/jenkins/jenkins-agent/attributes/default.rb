default['jenkins']['java_package'] = 'openjdk-21-jre'

default['jenkins']['agent']['user'] = 'jenkins'
default['jenkins']['agent']['group'] = 'jenkins'
default['jenkins']['agent']['home'] = '/var/lib/jenkins'
default['jenkins']['agent']['work_dir'] = '/var/lib/jenkins/agent'
default['jenkins']['agent']['ssh_public_key'] = ''
default['jenkins']['agent']['build_packages'] = %w(git curl build-essential openssh-server)
