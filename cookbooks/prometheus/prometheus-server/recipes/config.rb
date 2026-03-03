config_dir = node['prometheus']['server']['config_dir']
prom_user = node['prometheus']['server']['user']
prom_group = node['prometheus']['server']['group']

# Create placeholder bearer token files referenced by scrape configs so
# promtool validation does not fail before the real tokens are provisioned.
# The k8s-master::rbac recipe provisions the actual token on the master node
# at /etc/kubernetes/prometheus-token.txt — copy it to this server:
#   scp master-node:/etc/kubernetes/prometheus-token.txt /etc/prometheus/k8s_token
node['prometheus']['server']['scrape_configs'].each do |sc|
  next unless sc['bearer_token_file']

  file sc['bearer_token_file'] do
    owner prom_user
    group prom_group
    mode '0600'
    content 'PLACEHOLDER — replace with a real token'
    action :create_if_missing
  end
end

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
