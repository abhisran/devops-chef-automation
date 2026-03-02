# nagios-server Cookbook

Compiles and installs Nagios Core from source and configures host, hostgroup, and service monitoring via NRPE. Includes the Nagios web interface served by Apache.

## Requirements

### Platforms

- Debian/Ubuntu
- RHEL/CentOS/Fedora

### Chef

- Chef 16+

## Attributes

### Core Settings

| Attribute | Description | Default |
|-----------|-------------|---------|
| `node['nagios']['version']` | Nagios Core version to install | `4.5.11` |
| `node['nagios']['nrpe_version']` | NRPE plugin version to install | `4.1.0` |
| `node['nagios']['user']` | Nagios system user | `nagios` |
| `node['nagios']['group']` | Nagios system group | `nagios` |
| `node['nagios']['cmd_group']` | Nagios command group (includes web server user) | `nagcmd` |
| `node['nagios']['install_dir']` | Nagios installation directory | `/usr/local/nagios` |
| `node['nagios']['src_dir']` | Source download/compile directory | `/usr/local/src` |
| `node['nagios']['admin_user']` | Web UI admin username | `nagiosadmin` |
| `node['nagios']['admin_password']` | Web UI admin password (override in production!) | `nagios@123` |

### Hostgroups

`node['nagios']['hostgroups']` defines logical groups for service assignment. Defaults:

| Hostgroup | Description |
|-----------|-------------|
| `monitored-servers` | All monitored servers |
| `infrastructure-servers` | Infrastructure servers (non-K8s) |
| `k8s-cluster` | All Kubernetes nodes |
| `k8s-masters` | Kubernetes master nodes |
| `k8s-workers` | Kubernetes worker nodes |
| `jenkins-servers` | Jenkins controller nodes |
| `jenkins-agents` | Jenkins agent nodes |

### Monitored Hosts

`node['nagios']['monitored_hosts']` defines the hosts to monitor. Each entry supports `host_name`, `alias`, `address`, and `hostgroups`. See `attributes/default.rb` for the full default list.

### Hostgroup Services

`node['nagios']['hostgroup_services']` maps service checks to hostgroups. Default checks include:

| Hostgroup | Checks |
|-----------|--------|
| `monitored-servers` | Disk, Memory, Load, Processes, Zombies, SSH, Users |
| `infrastructure-servers` | HTTP, Swap |
| `k8s-cluster` | Kubelet, Containerd, Containerd Shim, Kube Proxy, Kubelet Health, Kube Proxy Health, Containerd Socket, DNS Resolution |
| `k8s-masters` | API Server, etcd, Scheduler (process + health), Controller Manager Health |
| `jenkins-servers` | Jenkins Process, Jenkins Web UI, Swap |
| `jenkins-agents` | Jenkins Agent User, Jenkins Agent Work Dir, Swap |

## Recipes

### default

Includes all other recipes in the correct order.

### install

Installs platform-specific build dependencies and web server packages (Apache). Downloads and compiles Nagios Core from source. Compiles and installs the NRPE plugin (`check_nrpe`) for communicating with remote NRPE clients. Creates the `nagios` user/group and `nagcmd` command group. Enables Apache CGI module and creates the `htpasswd` file for web UI authentication.

### config

Deploys two configuration files from templates:

- **nrpe_commands.cfg** — defines the `check_nrpe` command for executing remote checks
- **hosts.cfg** — defines hostgroups, hosts, and service definitions driven by node attributes

Registers both config files in `nagios.cfg` so Nagios loads them on startup.

### service

Enables and starts both the Nagios service and the web server (Apache on Debian, httpd on RHEL).

## Centralized Version Management

This cookbook supports loading version attributes from the `app_versions` Chef Vault. If the vault exists, it overrides the default attribute values at compile time. If the vault is not available, the hardcoded defaults in `attributes/default.rb` are used.

### Vault Keys

| Vault Key | Overrides Attribute |
|-----------|--------------------|
| `nagios.version` | `node['nagios']['version']` |
| `nagios.nrpe_version` | `node['nagios']['nrpe_version']` |

### Setup

```bash
knife vault create app_versions default \
  '{"nagios":{"version":"4.5.11","nrpe_version":"4.1.0"}}' \
  --search "role:nagios-server" \
  --admins "admin_user"
```

## Usage

### Install & Upload

```bash
cd nagios/nagios-server
berks install    # resolves cookbook dependencies
berks upload     # uploads cookbook + dependencies to Chef Server
```

Then add the cookbook to your node's run list:

```ruby
run_list 'recipe[nagios-server]'
```

### Override Admin Password

**Important:** Override the default admin password in a role or environment:

```ruby
default_attributes(
  'nagios' => {
    'admin_password' => 'your_secure_password'
  }
)
```

### Add Monitored Hosts

Override `monitored_hosts` to add or change the hosts being monitored:

```ruby
default_attributes(
  'nagios' => {
    'monitored_hosts' => [
      {
        'host_name' => 'web-server-01',
        'alias' => 'Web Server 1',
        'address' => '<HOST_IP>',
        'hostgroups' => %w(monitored-servers infrastructure-servers)
      }
    ]
  }
)
```

### Access the Web UI

After running `chef-client`, access the Nagios web interface at:

```
http://<nagios-server-ip>/nagios
```

Login with the `admin_user` and `admin_password` configured in the attributes.

## License

All Rights Reserved

## Author

Abhishek Ranjan
