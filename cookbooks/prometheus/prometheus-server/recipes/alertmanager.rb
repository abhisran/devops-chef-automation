# Alertmanager Installation and Service Management
version = node['prometheus']['server']['alertmanager']['version']
install_dir = node['prometheus']['server']['alertmanager']['install_dir']
config_dir = node['prometheus']['server']['alertmanager']['config_dir']
storage_path = node['prometheus']['server']['alertmanager']['storage_path']
prom_user = node['prometheus']['server']['user']
prom_group = node['prometheus']['server']['group']

# Determine architecture
arch = node['kernel']['machine'] == 'x86_64' ? 'amd64' : 'arm64'
tarball = "alertmanager-#{version}.linux-#{arch}.tar.gz"
download_url = "https://github.com/prometheus/alertmanager/releases/download/v#{version}/#{tarball}"

# Create directories
[install_dir, config_dir, storage_path].each do |dir|
  directory dir do
    owner prom_user
    group prom_group
    mode '0755'
    recursive true
  end
end

# Download and extract Alertmanager
remote_file "/tmp/#{tarball}" do
  source download_url
  not_if { ::File.exist?("#{install_dir}/alertmanager") && `#{install_dir}/alertmanager --version 2>&1`.include?(version) }
end

execute 'extract_alertmanager' do
  command <<-EOH
    tar xzf /tmp/#{tarball} -C /tmp
    cp /tmp/alertmanager-#{version}.linux-#{arch}/alertmanager #{install_dir}/alertmanager
    cp /tmp/alertmanager-#{version}.linux-#{arch}/amtool #{install_dir}/amtool
    chown -R #{prom_user}:#{prom_group} #{install_dir}
    rm -rf /tmp/alertmanager-#{version}.linux-#{arch} /tmp/#{tarball}
  EOH
  not_if { ::File.exist?("#{install_dir}/alertmanager") && `#{install_dir}/alertmanager --version 2>&1`.include?(version) }
end

# Symlink binaries
%w(alertmanager amtool).each do |bin|
  link "/usr/local/bin/#{bin}" do
    to "#{install_dir}/#{bin}"
  end
end

# Fetch secrets from Chef Vault securely
telegram_enabled = node['prometheus']['server']['alertmanager']['telegram']['enabled']
telegram_token = nil
telegram_chat_id = nil

if telegram_enabled
  begin
    telegram_secrets = chef_vault_item('alertmanager_credentials', 'telegram')
    telegram_token = telegram_secrets['bot_token']
    telegram_chat_id = telegram_secrets['chat_id']
  rescue StandardError => e
    Chef::Log.warn("Alertmanager Telegram vault not available: #{e.message}. Falling back to attributes.")
    telegram_token = node['prometheus']['server']['alertmanager']['telegram']['bot_token']
    telegram_chat_id = node['prometheus']['server']['alertmanager']['telegram']['chat_id']
  end

  if telegram_token.nil? || telegram_token.to_s.empty? || telegram_chat_id.nil? || telegram_chat_id.to_s.empty?
    Chef::Log.warn('Alertmanager Telegram credentials are missing. Disabling Telegram notifications.')
    telegram_enabled = false
  end
end

# Alertmanager configuration
template "#{config_dir}/alertmanager.yml" do
  source 'alertmanager.yml.erb'
  owner prom_user
  group prom_group
  mode '0600'
  sensitive true
  variables(
    telegram_enabled: telegram_enabled,
    telegram_token: telegram_token,
    telegram_chat_id: telegram_chat_id
  )
  notifies :restart, 'service[alertmanager]', :delayed
end

# Validate alertmanager config
execute 'validate_alertmanager_config' do
  command "#{install_dir}/amtool check-config #{config_dir}/alertmanager.yml"
  action :nothing
  subscribes :run, "template[#{config_dir}/alertmanager.yml]", :immediately
end

# Systemd service unit
systemd_unit 'alertmanager.service' do
  content <<~EOH
    [Unit]
    Description=Prometheus Alertmanager
    After=network-online.target
    Wants=network-online.target

    [Service]
    User=#{prom_user}
    Group=#{prom_group}
    Type=simple
    ExecStart=#{install_dir}/alertmanager \
      --config.file=#{config_dir}/alertmanager.yml \
      --storage.path=#{storage_path} \
      --web.listen-address=#{node['prometheus']['server']['alertmanager']['listen_address']}:#{node['prometheus']['server']['alertmanager']['port']}

    ExecReload=/bin/kill -HUP $MAINPID
    Restart=always

    [Install]
    WantedBy=multi-user.target
  EOH
  action [:create, :enable]
  notifies :run, 'execute[systemctl-daemon-reload-alertmanager]', :immediately
  notifies :restart, 'service[alertmanager]', :delayed
end

execute 'systemctl-daemon-reload-alertmanager' do
  command 'systemctl daemon-reload'
  action :nothing
end

service 'alertmanager' do
  supports restart: true, status: true, reload: true
  action [:enable, :start]
end
