default['jenkins']['java_package'] = 'openjdk-21-jre'
default['jenkins']['port'] = 8080
default['jenkins']['java_args'] = '-Xmx1024m -Xms512m'
default['jenkins']['home'] = '/var/lib/jenkins'
default['jenkins']['user'] = 'jenkins'
default['jenkins']['group'] = 'jenkins'

default['jenkins']['vault']['name'] = 'jenkins_credentials'
default['jenkins']['vault']['item'] = 'ssh_keys'

default['jenkins']['casc']['enabled'] = true
default['jenkins']['casc']['config_path'] = '/var/lib/jenkins/jenkins.yaml'
default['jenkins']['casc']['jenkins_url'] = 'http://192.168.1.75:8080/'
default['jenkins']['casc']['controller_executors'] = 0

default['jenkins']['agents'] = [
  {
    'name' => 'agent-01',
    'host' => '192.168.1.76',
    'label' => 'linux docker',
    'executors' => 2,
    'work_dir' => '/var/lib/jenkins/agent',
    'java_path' => '/usr/bin/java',
    'description' => 'Jenkins build agent 01',
  },
]

default['jenkins']['plugin_manager']['version'] = '2.13.0'
default['jenkins']['plugin_manager']['jar_path'] = '/opt/jenkins-plugin-manager.jar'
default['jenkins']['war_path'] = '/usr/share/java/jenkins.war'

# Firewall
default['firewall']['rule_groups']['jenkins_server']['enabled'] = true

default['jenkins']['plugins'] = %w(
  ssh-slaves
  ssh-credentials
  ssh-agent
  credentials-binding
  plain-credentials
  git
  github
  github-branch-source
  workflow-aggregator
  docker-plugin
  docker-workflow
  docker-commons
  kubernetes
  configuration-as-code
  job-dsl
  matrix-auth
  antisamy-markup-formatter
  authorize-project
  blueocean
  dashboard-view
  timestamper
  ws-cleanup
  rebuild
  build-timeout
  mailer
  email-ext
  maven-plugin
  gradle
  nodejs
)
