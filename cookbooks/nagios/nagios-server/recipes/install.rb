package %w(
  apache2
  php
  libapache2-mod-php
  build-essential
  libgd-dev
  unzip
)

group node['nagios']['group']

user node['nagios']['user'] do
  group node['nagios']['group']
  shell '/bin/bash'
  manage_home true
end

group node['nagios']['cmd_group']

directory node['nagios']['src_dir'] do
  recursive true
end

remote_file "#{node['nagios']['src_dir']}/nagios.tar.gz" do
  source "https://assets.nagios.com/downloads/nagioscore/releases/nagios-#{node['nagios']['version']}.tar.gz"
  not_if { ::File.exist?("#{node['nagios']['install_dir']}/bin/nagios") }
end

execute 'compile_nagios' do
  cwd node['nagios']['src_dir']
  command <<-EOH
    tar xzf nagios.tar.gz
    cd nagios-#{node['nagios']['version']}
    ./configure --with-command-group=#{node['nagios']['cmd_group']}
    make all
    make install
    make install-init
    make install-config
    make install-commandmode
  EOH
  not_if { ::File.exist?("#{node['nagios']['install_dir']}/bin/nagios") }
end
