# Deploy systemd service unit
template '/etc/systemd/system/node_exporter.service' do
  source 'node_exporter.service.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    install_dir: node['prometheus']['node_exporter']['install_dir'],
    user: node['prometheus']['node_exporter']['user'],
    group: node['prometheus']['node_exporter']['group'],
    listen_address: node['prometheus']['node_exporter']['listen_address'],
    port: node['prometheus']['node_exporter']['port'],
    textfile_dir: node['prometheus']['node_exporter']['textfile_dir'],
    enabled_collectors: node['prometheus']['node_exporter']['enabled_collectors'],
    disabled_collectors: node['prometheus']['node_exporter']['disabled_collectors'],
    extra_flags: node['prometheus']['node_exporter']['extra_flags']
  )
  notifies :run, 'execute[systemctl-daemon-reload-node-exporter]', :immediately
  notifies :restart, 'service[node_exporter]', :delayed
end

execute 'systemctl-daemon-reload-node-exporter' do
  command 'systemctl daemon-reload'
  action :nothing
end

service 'node_exporter' do
  supports restart: true, status: true
  action [:enable, :start]
end
