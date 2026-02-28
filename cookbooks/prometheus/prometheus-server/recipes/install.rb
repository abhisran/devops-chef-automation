version = node['prometheus']['server']['version']
install_dir = node['prometheus']['server']['install_dir']
config_dir = node['prometheus']['server']['config_dir']
data_dir = node['prometheus']['server']['data_dir']
prom_user = node['prometheus']['server']['user']
prom_group = node['prometheus']['server']['group']

# Determine architecture
arch = node['kernel']['machine'] == 'x86_64' ? 'amd64' : 'arm64'
tarball = "prometheus-#{version}.linux-#{arch}.tar.gz"
download_url = "https://github.com/prometheus/prometheus/releases/download/v#{version}/#{tarball}"

# Create prometheus user and group
group prom_group do
  system true
end

user prom_user do
  group prom_group
  shell '/usr/sbin/nologin'
  system true
  manage_home false
end

# Create directories
[install_dir, config_dir, "#{config_dir}/rules", data_dir].each do |dir|
  directory dir do
    owner prom_user
    group prom_group
    mode '0755'
    recursive true
  end
end

# Download and extract Prometheus
remote_file "/tmp/#{tarball}" do
  source download_url
  not_if { ::File.exist?("#{install_dir}/prometheus") && `#{install_dir}/prometheus --version 2>&1`.include?(version) }
end

execute 'extract_prometheus' do
  command <<-EOH
    tar xzf /tmp/#{tarball} -C /tmp
    cp /tmp/prometheus-#{version}.linux-#{arch}/prometheus #{install_dir}/prometheus
    cp /tmp/prometheus-#{version}.linux-#{arch}/promtool #{install_dir}/promtool
    cp -r /tmp/prometheus-#{version}.linux-#{arch}/consoles #{config_dir}/
    cp -r /tmp/prometheus-#{version}.linux-#{arch}/console_libraries #{config_dir}/
    chown -R #{prom_user}:#{prom_group} #{install_dir} #{config_dir}
    rm -rf /tmp/prometheus-#{version}.linux-#{arch} /tmp/#{tarball}
  EOH
  not_if { ::File.exist?("#{install_dir}/prometheus") && `#{install_dir}/prometheus --version 2>&1`.include?(version) }
end

# Symlink binaries to /usr/local/bin
%w(prometheus promtool).each do |bin|
  link "/usr/local/bin/#{bin}" do
    to "#{install_dir}/#{bin}"
  end
end
