# nagios-client Cookbook

Installs and configures NRPE (Nagios Remote Plugin Executor) client for Nagios monitoring. Includes check commands for system health, Kubernetes clusters, and Jenkins CI/CD infrastructure.

## Requirements

### Platforms

- Debian/Ubuntu (tested on Ubuntu 22.04)
- RHEL/CentOS/Fedora

### Chef

- Chef 16+

## Attributes

### NRPE Configuration

| Attribute | Description | Default |
|-----------|-------------|--------|
| `node['nagios']['server']['ip']` | Nagios server IP — **must be overridden** (auto-added to allowed_hosts) | `192.168.1.55` |
| `node['nagios']['nrpe']['user']` | NRPE daemon user | `nagios` |
| `node['nagios']['nrpe']['group']` | NRPE daemon group | `nagios` |
| `node['nagios']['nrpe']['allowed_hosts']` | Array of IPs allowed to connect | `['127.0.0.1', '::1', node['nagios']['server']['ip']]` |
| `node['nagios']['nrpe']['server_port']` | NRPE listen port | `5666` |
| `node['nagios']['nrpe']['dont_blame_nrpe']` | Allow command arguments (0=no, 1=yes) | `0` |
| `node['nagios']['nrpe']['allow_bash_command_substitution']` | Allow bash command substitution (0=no, 1=yes) | `0` |
| `node['nagios']['nrpe']['debug']` | Enable debug logging (0=no, 1=yes) | `0` |
| `node['nagios']['nrpe']['command_timeout']` | Command execution timeout (seconds) | `60` |
| `node['nagios']['nrpe']['connection_timeout']` | Connection timeout (seconds) | `300` |
| `node['nagios']['nrpe']['plugin_dir']` | Path to Nagios plugins directory | `/usr/lib/nagios/plugins` |

### System Check Commands

Configured via `node['nagios']['nrpe']['commands']`:

| Command | Description |
|---------|-------------|
| `check_disk` | Check disk usage (warning 20%, critical 10%) |
| `check_load` | Check system load average |
| `check_swap` | Check swap usage |
| `check_procs` | Check total processes |
| `check_zombie_procs` | Check zombie processes |
| `check_ssh` | Check SSH service |
| `check_http` | Check HTTP service |
| `check_users` | Check logged in users |

### Memory Check

The `check_mem` command is defined in the local config file (no external plugin required). It uses the `free` command to calculate memory usage percentage, with configurable warning (80%) and critical (90%) thresholds.

### Kubernetes Check Commands

Configured via `node['nagios']['nrpe']['k8s_commands']` (process checks):

| Command | Description |
|---------|-------------|
| `check_kubelet` | Check kubelet process |
| `check_containerd` | Check containerd process |
| `check_containerd_shim` | Check containerd-shim process |
| `check_kube_proxy` | Check kube-proxy process |
| `check_kube_apiserver` | Check kube-apiserver process (master only) |
| `check_etcd` | Check etcd process (master only) |
| `check_kube_scheduler` | Check kube-scheduler process (master only) |
| `check_kube_controller` | Check kube-controller-manager process (master only) |

Configured via `node['nagios']['nrpe']['k8s_health_commands']` (health endpoints):

| Command | Description |
|---------|-------------|
| `check_kubelet_health` | Check kubelet health endpoint (port 10248) |
| `check_kube_proxy_health` | Check kube-proxy health endpoint (port 10256) |
| `check_dns_resolution` | Check CoreDNS resolution via cluster DNS |
| `check_containerd_socket` | Verify containerd socket exists |

Configured via `node['nagios']['nrpe']['k8s_master_health_commands']` (master only):

| Command | Description |
|---------|-------------|
| `check_apiserver_health` | Check API server health endpoint (port 6443) |
| `check_etcd_health` | Check etcd health endpoint (port 2381) |
| `check_scheduler_health` | Check scheduler health endpoint (port 10259) |
| `check_controller_health` | Check controller-manager health endpoint (port 10257) |

### Jenkins Check Commands

Configured via `node['nagios']['nrpe']['jenkins_commands']` and related attributes:

| Command | Description |
|---------|-------------|
| `check_jenkins_process` | Check Jenkins Java process (server only) |
| `check_jenkins_http` | Check Jenkins web UI on port 8080 (server only) |
| `check_jenkins_agent_user` | Verify jenkins user exists (agent only) |
| `check_jenkins_agent_workdir` | Verify agent work directory exists (agent only) |

## Usage

### Install & Upload

```bash
cd nagios/nagios-client
berks install    # resolves cookbook dependencies
berks upload     # uploads cookbook + dependencies to Chef Server
```

Then add the cookbook to your node's run list:

```ruby
run_list 'recipe[nagios-client]'
```

### Configure Nagios Server Access

**Important:** Override `node['nagios']['server']['ip']` with your Nagios server's actual IP. This value is automatically included in `allowed_hosts` so the NRPE daemon accepts connections from the server:

```ruby
default_attributes(
  'nagios' => {
    'server' => {
      'ip' => '<NAGIOS_SERVER_IP>'
    }
  }
)
```

### Custom Check Commands

Add custom check commands via the `custom_commands` attribute:

```ruby
default_attributes(
  'nagios' => {
    'nrpe' => {
      'custom_commands' => {
        'check_mysql' => '/usr/lib/nagios/plugins/check_mysql -H localhost -u nagios -p password',
        'check_nginx' => '/usr/lib/nagios/plugins/check_http -H localhost -p 80'
      }
    }
  }
)
```

### Override Default Command Arguments

You can customize the default command arguments:

```ruby
default_attributes(
  'nagios' => {
    'nrpe' => {
      'commands' => {
        'check_disk' => '-w 30% -c 20% -p /',
        'check_load' => '-w 20,15,10 -c 40,35,30'
      }
    }
  }
)
```

## Recipes

### default

Includes all other recipes in the correct order.

### install

Creates the nagios user and group. Installs NRPE daemon and Nagios monitoring plugins via platform packages.

### config

Deploys the main NRPE configuration file (`nrpe.cfg`) with daemon settings and standard check commands. On Debian, also deploys a local configuration file (`nrpe_local.cfg`) containing the memory check, Kubernetes checks, Jenkins checks, and any custom commands.

### service

Enables and starts the NRPE service (`nagios-nrpe-server` on Debian, `nrpe` on RHEL).

## Testing Connection

From the Nagios server, test the NRPE connection:

```bash
/usr/local/nagios/libexec/check_nrpe -H <client_ip>
```

Test a specific command:

```bash
/usr/local/nagios/libexec/check_nrpe -H <client_ip> -c check_load
```

## License

Apache 2.0

## Author

Abhishek Ranjan
