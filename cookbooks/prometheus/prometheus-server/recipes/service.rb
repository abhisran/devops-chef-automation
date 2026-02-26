# Deploy systemd service unit
template '/etc/systemd/system/prometheus.service' do
  source 'prometheus.service.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    install_dir: node['prometheus']['server']['install_dir'],
    config_dir: node['prometheus']['server']['config_dir'],
    data_dir: node['prometheus']['server']['data_dir'],
    user: node['prometheus']['server']['user'],
    group: node['prometheus']['server']['group'],
    listen_address: node['prometheus']['server']['listen_address'],
    port: node['prometheus']['server']['port'],
    retention_time: node['prometheus']['server']['retention_time'],
    retention_size: node['prometheus']['server']['retention_size']
  )
  notifies :run, 'execute[systemctl-daemon-reload-prometheus]', :immediately
  notifies :restart, 'service[prometheus]', :delayed
end

execute 'systemctl-daemon-reload-prometheus' do
  command 'systemctl daemon-reload'
  action :nothing
end

service 'prometheus' do
  supports restart: true, status: true, reload: true
  reload_command 'kill -HUP $(pidof prometheus)'
  action [:enable, :start]
end
