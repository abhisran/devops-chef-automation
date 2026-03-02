include_recipe 'nagios-client::install'
include_recipe 'nagios-client::config'
include_recipe 'nagios-client::service'
include_recipe 'firewall'
