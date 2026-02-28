version = node['prometheus']['node_exporter']['version']
install_dir = node['prometheus']['node_exporter']['install_dir']
textfile_dir = node['prometheus']['node_exporter']['textfile_dir']
exporter_user = node['prometheus']['node_exporter']['user']
exporter_group = node['prometheus']['node_exporter']['group']

# Determine architecture
arch = node['kernel']['machine'] == 'x86_64' ? 'amd64' : 'arm64'
tarball = "node_exporter-#{version}.linux-#{arch}.tar.gz"
download_url = "https://github.com/prometheus/node_exporter/releases/download/v#{version}/#{tarball}"

# Create node_exporter user and group
group exporter_group do
  system true
end

user exporter_user do
  group exporter_group
  shell '/usr/sbin/nologin'
  system true
  manage_home false
end

# Create directories
[install_dir, textfile_dir].each do |dir|
  directory dir do
    owner exporter_user
    group exporter_group
    mode '0755'
    recursive true
  end
end

# Download and extract node_exporter
remote_file "/tmp/#{tarball}" do
  source download_url
  not_if { ::File.exist?("#{install_dir}/node_exporter") && `#{install_dir}/node_exporter --version 2>&1`.include?(version) }
end

execute 'extract_node_exporter' do
  command <<-EOH
    tar xzf /tmp/#{tarball} -C /tmp
    cp /tmp/node_exporter-#{version}.linux-#{arch}/node_exporter #{install_dir}/node_exporter
    chown #{exporter_user}:#{exporter_group} #{install_dir}/node_exporter
    rm -rf /tmp/node_exporter-#{version}.linux-#{arch} /tmp/#{tarball}
  EOH
  not_if { ::File.exist?("#{install_dir}/node_exporter") && `#{install_dir}/node_exporter --version 2>&1`.include?(version) }
end

# Symlink binary to /usr/local/bin
link '/usr/local/bin/node_exporter' do
  to "#{install_dir}/node_exporter"
end
