include_recipe 'apt'
include_recipe 'package'
include_recipe 'prometheus-client'

include_recipe 'nagios-client::install'
include_recipe 'nagios-client::config'
include_recipe 'nagios-client::service'
include_recipe 'firewall'
