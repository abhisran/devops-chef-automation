config_file = node['grafana']['server']['config_file']
provisioning_dir = node['grafana']['server']['provisioning_dir']
dashboard_dir = node['grafana']['server']['dashboard_dir']

# Ensure provisioning directories exist
%W(#{provisioning_dir}/datasources #{provisioning_dir}/dashboards #{provisioning_dir}/notifiers #{dashboard_dir}).each do |dir|
  directory dir do
    owner 'grafana'
    group 'grafana'
    mode '0755'
    recursive true
  end
end

# Deploy grafana.ini
template config_file do
  source 'grafana.ini.erb'
  owner 'root'
  group 'grafana'
  mode '0640'
  variables(
    http_addr: node['grafana']['server']['http_addr'],
    http_port: node['grafana']['server']['http_port'],
    domain: node['grafana']['server']['domain'],
    root_url: node['grafana']['server']['root_url'],
    data_dir: node['grafana']['server']['data_dir'],
    log_dir: node['grafana']['server']['log_dir'],
    provisioning_dir: provisioning_dir,
    admin_user: node['grafana']['server']['admin_user'],
    admin_password: node['grafana']['server']['admin_password'],
    anonymous_enabled: node['grafana']['server']['anonymous_enabled'],
    anonymous_org_role: node['grafana']['server']['anonymous_org_role'],
    reporting_enabled: node['grafana']['server']['reporting_enabled'],
    check_for_updates: node['grafana']['server']['check_for_updates'],
    metrics_enabled: node['grafana']['server']['metrics_enabled'],
    log_mode: node['grafana']['server']['log_mode'],
    log_level: node['grafana']['server']['log_level']
  )
  notifies :restart, 'service[grafana-server]', :delayed
end

# Provision datasources
template "#{provisioning_dir}/datasources/datasources.yml" do
  source 'datasources.yml.erb'
  owner 'grafana'
  group 'grafana'
  mode '0640'
  variables(
    datasources: node['grafana']['server']['datasources']
  )
  notifies :restart, 'service[grafana-server]', :delayed
end

# Provision dashboard provider (points to /var/lib/grafana/dashboards)
template "#{provisioning_dir}/dashboards/dashboards.yml" do
  source 'dashboard_provider.yml.erb'
  owner 'grafana'
  group 'grafana'
  mode '0640'
  variables(
    dashboard_dir: dashboard_dir
  )
  notifies :restart, 'service[grafana-server]', :delayed
end
