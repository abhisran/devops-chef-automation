# node_exporter is configured entirely via command-line flags in the systemd
# service unit (see service.rb / node_exporter.service.erb). This recipe
# handles any file-based configuration such as the textfile collector directory.

textfile_dir = node['prometheus']['node_exporter']['textfile_dir']
exporter_user = node['prometheus']['node_exporter']['user']
exporter_group = node['prometheus']['node_exporter']['group']

# Ensure textfile collector directory exists with correct permissions
directory textfile_dir do
  owner exporter_user
  group exporter_group
  mode '0755'
  recursive true
end

# Deploy Chef client metrics collector script for textfile collector
template '/usr/local/bin/chef_client_metrics.sh' do
  source 'chef_client_metrics.sh.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables(
    textfile_dir: textfile_dir
  )
end

# Run the collector every 5 minutes via cron
cron 'chef_client_metrics' do
  minute '*/5'
  command '/usr/local/bin/chef_client_metrics.sh'
  user 'root'
end
