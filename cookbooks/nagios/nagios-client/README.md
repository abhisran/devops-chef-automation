# nagios-client Cookbook

Installs and configures NRPE (Nagios Remote Plugin Executor) client for Nagios monitoring.

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
| `node['nagios']['nrpe']['user']` | NRPE daemon user | `nagios` |
| `node['nagios']['nrpe']['group']` | NRPE daemon group | `nagios` |
| `node['nagios']['nrpe']['allowed_hosts']` | Array of Nagios server IPs allowed to connect | `['127.0.0.1', '::1']` |
| `node['nagios']['nrpe']['server_port']` | NRPE listen port | `5666` |
| `node['nagios']['nrpe']['dont_blame_nrpe']` | Allow command arguments (0=no, 1=yes) | `0` |
| `node['nagios']['nrpe']['command_timeout']` | Command execution timeout | `60` |
| `node['nagios']['nrpe']['connection_timeout']` | Connection timeout | `300` |

### Check Commands

The following commands are configured by default:

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

## Usage

### Basic Usage

Add the cookbook to your node's run list:

```ruby
run_list 'recipe[nagios-client]'
```

### Configure Nagios Server Access

**IMPORTANT:** You must override the `allowed_hosts` attribute to allow your Nagios server to connect:

```ruby
# In a role or environment file
default_attributes(
  'nagios' => {
    'nrpe' => {
      'allowed_hosts' => ['192.168.1.50', '127.0.0.1']  # Add your Nagios server IP
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
        'check_disk' => '-w 30% -c 20% -p /',  # More lenient thresholds
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

Installs NRPE daemon and Nagios plugins packages.

### config

Configures NRPE with allowed hosts and check commands.

### service

Enables and starts the NRPE service.

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
