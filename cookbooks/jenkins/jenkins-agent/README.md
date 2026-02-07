# jenkins-agent Cookbook

Installs and configures a Jenkins SSH agent (worker node). The Jenkins server connects to this node via SSH to run builds.

## Requirements

### Platforms

- Debian/Ubuntu

### Chef

- Chef 16+

## Attributes

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['jenkins']['java_package']` | Java package to install | `openjdk-21-jre` |
| `node['jenkins']['agent']['user']` | Jenkins agent user | `jenkins` |
| `node['jenkins']['agent']['group']` | Jenkins agent group | `jenkins` |
| `node['jenkins']['agent']['home']` | Jenkins agent home directory | `/var/lib/jenkins` |
| `node['jenkins']['agent']['work_dir']` | Agent workspace/remoting directory | `/var/lib/jenkins/agent` |
| `node['jenkins']['agent']['ssh_public_key']` | Jenkins server's SSH public key | `''` |
| `node['jenkins']['agent']['build_packages']` | Build tools to install | `git curl build-essential openssh-server` |

## Usage

Add the cookbook to your node's run list:

```ruby
run_list 'recipe[jenkins-agent]'
```

**IMPORTANT:** You must override `ssh_public_key` with the Jenkins server's public key so it can SSH into this agent:

```ruby
default_attributes(
  'jenkins' => {
    'agent' => {
      'ssh_public_key' => 'ssh-rsa AAAA... jenkins-server'
    }
  }
)
```

## Recipes

### default

Includes all other recipes in the correct order.

### install

Installs Java (fontconfig + OpenJDK 21), creates the jenkins user and group, and installs build tools.

### config

Creates the `.ssh` directory and `authorized_keys` file for SSH access from the Jenkins server. Creates the agent work directory.

### service

Ensures the SSH service is enabled and running, then logs that the agent is ready for connections from the Jenkins server.

## Author

Abhishek Ranjan
