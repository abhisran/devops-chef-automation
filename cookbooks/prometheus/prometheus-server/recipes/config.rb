config_dir = node['prometheus']['server']['config_dir']
prom_user = node['prometheus']['server']['user']
prom_group = node['prometheus']['server']['group']

# Deploy main Prometheus configuration
template "#{config_dir}/prometheus.yml" do
  source 'prometheus.yml.erb'
  owner prom_user
  group prom_group
  mode '0644'
  variables(
    scrape_interval: node['prometheus']['server']['scrape_interval'],
    evaluation_interval: node['prometheus']['server']['evaluation_interval'],
    scrape_timeout: node['prometheus']['server']['scrape_timeout'],
    scrape_configs: node['prometheus']['server']['scrape_configs'],
    alertmanager_enabled: node['prometheus']['server']['alertmanager']['enabled'],
    alertmanager_targets: node['prometheus']['server']['alertmanager']['targets'],
    alert_rules_enabled: node['prometheus']['server']['alert_rules']['enabled']
  )
  notifies :reload, 'service[prometheus]', :delayed
end

# Deploy alert rules
if node['prometheus']['server']['alert_rules']['enabled']
  template "#{config_dir}/rules/alert_rules.yml" do
    source 'alert_rules.yml.erb'
    owner prom_user
    group prom_group
    mode '0644'
    variables(
      groups: node['prometheus']['server']['alert_rules']['groups']
    )
    notifies :reload, 'service[prometheus]', :delayed
  end
end

# Validate configuration (triggers on either prometheus.yml or alert rules changes)
execute 'validate_prometheus_config' do
  command "#{node['prometheus']['server']['install_dir']}/promtool check config #{config_dir}/prometheus.yml"
  action :nothing
  subscribes :run, "template[#{config_dir}/prometheus.yml]", :immediately
  subscribes :run, "template[#{config_dir}/rules/alert_rules.yml]", :immediately
end
