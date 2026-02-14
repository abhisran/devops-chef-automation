# jenkins-server Cookbook

Installs and configures a Jenkins CI/CD server (controller) on Debian/Ubuntu.

## Requirements

### Platforms

- Debian/Ubuntu

### Chef

- Chef 16+

### Dependencies

- `chef-vault` (~> 4.0)

## Chef Vault Setup (One-Time)

SSH credentials are managed via Chef Vault. Both `jenkins-server` and `jenkins-agent` cookbooks read from the same vault, so you only set this up once.

### 1. Generate an SSH key pair (PEM format — required by Jenkins)

```bash
ssh-keygen -t rsa -b 4096 -m PEM -f jenkins_ssh_key -N '' -C 'jenkins-agent-key'
```

### 2. Create the Chef Vault

```bash
# Create a JSON file with the key contents (jq handles multi-line key escaping)
jq -n \
  --arg priv "$(cat jenkins_ssh_key)" \
  --arg pub "$(cat jenkins_ssh_key.pub)" \
  '{"id":"ssh_keys","private_key":$priv,"public_key":$pub}' > jenkins_ssh_keys.json

# Create the vault (grant access to server + agent nodes)
# Replace <CHEF_USERNAME> with your Chef Server username (check: knife user list)
knife vault create jenkins_credentials ssh_keys \
  --json jenkins_ssh_keys.json \
  --search 'recipe:jenkins-server OR recipe:jenkins-agent' \
  --admins '<CHEF_USERNAME>'

# Clean up local files
rm -f jenkins_ssh_key jenkins_ssh_key.pub jenkins_ssh_keys.json
```

### 3. Destroy existing credentials (if re-creating from scratch)

```bash
# On the Jenkins server node
rm -f /var/lib/jenkins/.ssh/id_rsa /var/lib/jenkins/.ssh/id_rsa.pub

# Delete old vault and re-create
knife vault delete jenkins_credentials ssh_keys -y
# Then repeat step 1 & 2 above
```

### 4. Run Chef on both nodes

```bash
# Server first, then agent
chef-client  # on jenkins server
chef-client  # on jenkins agent
```

### Refreshing vault access for new nodes

When adding a new agent node, refresh the vault so it can decrypt:

```bash
knife vault refresh jenkins_credentials ssh_keys \
  --search 'recipe:jenkins-server OR recipe:jenkins-agent'
```

## Attributes

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['jenkins']['java_package']` | Java package to install | `openjdk-21-jre` |
| `node['jenkins']['port']` | Jenkins HTTP port | `8080` |
| `node['jenkins']['java_args']` | JVM memory arguments | `-Xmx1024m -Xms512m` |
| `node['jenkins']['home']` | Jenkins home directory | `/var/lib/jenkins` |
| `node['jenkins']['user']` | Jenkins system user | `jenkins` |
| `node['jenkins']['group']` | Jenkins system group | `jenkins` |
| `node['jenkins']['vault']['name']` | Chef Vault name for SSH credentials | `jenkins_credentials` |
| `node['jenkins']['vault']['item']` | Chef Vault item name | `ssh_keys` |
| `node['jenkins']['plugin_manager']['version']` | jenkins-plugin-manager version | `2.13.0` |
| `node['jenkins']['plugin_manager']['jar_path']` | Path to plugin manager JAR | `/opt/jenkins-plugin-manager.jar` |
| `node['jenkins']['war_path']` | Path to Jenkins WAR file | `/usr/share/java/jenkins.war` |
| `node['jenkins']['plugins']` | List of plugins to install | See below |
| `node['jenkins']['casc']['enabled']` | Enable JCasC auto-configuration | `true` |
| `node['jenkins']['casc']['config_path']` | Path to the JCasC YAML file | `/var/lib/jenkins/jenkins.yaml` |
| `node['jenkins']['casc']['jenkins_url']` | Jenkins URL for notifications/webhooks — **override with your server's IP** | `http://192.168.1.56:8080/` |
| `node['jenkins']['casc']['controller_executors']` | Number of executors on the controller (0 = agents only) | `0` |
| `node['jenkins']['agents']` | List of agent node definitions | See below |

## Recipes

### default

Includes all other recipes in the correct order.

### install

Installs OpenJDK, adds the Jenkins official apt repository with GPG key, and installs the Jenkins package.

### config

Deploys `/etc/default/jenkins` and a systemd override at `/etc/systemd/system/jenkins.service.d/override.conf` for compatibility with both legacy and modern Jenkins packages. Reads the SSH key pair from Chef Vault and deploys it to `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`.

### plugins

Downloads the official [jenkins-plugin-manager](https://github.com/jenkinsci/plugin-installation-manager-tool) CLI tool and installs plugins from `node['jenkins']['plugins']`. Automatically resolves plugin dependencies. Only re-runs when the plugin list changes.

Default plugins:

| Category | Plugins |
|----------|---------|
| SSH / Credentials | ssh-slaves, ssh-credentials, ssh-agent, credentials-binding, plain-credentials |
| Git | git, github, github-branch-source |
| Pipeline | workflow-aggregator |
| Docker | docker-plugin, docker-workflow, docker-commons |
| Kubernetes | kubernetes |
| Configuration | configuration-as-code, job-dsl |
| Security | matrix-auth, antisamy-markup-formatter, authorize-project |
| UI | blueocean, dashboard-view |
| Utility | timestamper, ws-cleanup, rebuild, build-timeout, mailer, email-ext |
| Build Tools | maven-plugin, gradle, nodejs |

### casc

Uses [Jenkins Configuration as Code (JCasC)](https://www.jenkins.io/projects/jcasc/) to idempotently register agent nodes, configure SSH credentials, and set core Jenkins settings. Renders a `jenkins.yaml` file and sets the `CASC_JENKINS_CONFIG` environment variable so Jenkins loads it on every startup.

This recipe automatically:
- Reads the SSH private key from Chef Vault for Jenkins credentials
- Registers all agent nodes defined in `node['jenkins']['agents']` with SSH launcher
- Sets the Jenkins URL for build notifications and webhooks
- Re-applies configuration on every Jenkins restart (fully idempotent)

### service

Enables and starts the Jenkins service.

## Usage

### Install & Upload

```bash
cd jenkins/jenkins-server
berks install    # resolves cookbook dependencies
berks upload     # uploads cookbook + dependencies to Chef Server
```

Then add the cookbook to your node's run list:

```ruby
run_list 'recipe[jenkins-server]'
```

### Agent Registration (Automated via JCasC)

Agent nodes are automatically registered via Configuration as Code. The cookbook:
1. Reads the SSH private key from Chef Vault
2. Configures SSH credentials in Jenkins using JCasC
3. Registers each agent defined in `node['jenkins']['agents']` as a permanent SSH node

Agent configuration example (override the IP with your agent's address):

```ruby
default['jenkins']['agents'] = [
  {
    'name' => 'agent-01',
    'host' => '<AGENT_IP>',         # replace with your agent's IP
    'label' => 'linux docker',
    'executors' => 2,
    'work_dir' => '/var/lib/jenkins/agent',
    'java_path' => '/usr/bin/java',
    'description' => 'Jenkins build agent 01',
  },
]
```

Each agent hash supports: `name`, `host`, `label`, `executors`, `work_dir`, `java_path`, and `description`.

To add more agents, override the attribute in a role or environment:

```ruby
default_attributes(
  'jenkins' => {
    'agents' => [
      { 'name' => 'agent-01', 'host' => '<AGENT_01_IP>', 'label' => 'linux docker', 'executors' => 2, 'work_dir' => '/var/lib/jenkins/agent', 'java_path' => '/usr/bin/java', 'description' => 'Build agent 01' },
      { 'name' => 'agent-02', 'host' => '<AGENT_02_IP>', 'label' => 'linux docker', 'executors' => 4, 'work_dir' => '/var/lib/jenkins/agent', 'java_path' => '/usr/bin/java', 'description' => 'Build agent 02' },
    ]
  }
)
```

**Prerequisite**: The Chef Vault `jenkins_credentials/ssh_keys` must be created before running Chef on any node. See [Chef Vault Setup](#chef-vault-setup-one-time) above.

### Override Attributes

```ruby
default_attributes(
  'jenkins' => {
    'port' => 9090,
    'java_args' => '-Xmx2048m -Xms1024m'
  }
)
```

### Customize Plugins

Override the plugin list in a role, environment, or wrapper cookbook:

```ruby
default_attributes(
  'jenkins' => {
    'plugins' => %w(
      workflow-aggregator
      git
      ssh-slaves
      credentials-binding
    )
  }
)
```

## License

All Rights Reserved

## Author

Abhishek Ranjan
