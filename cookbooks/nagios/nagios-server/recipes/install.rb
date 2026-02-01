# Platform-specific packages
case node['platform_family']
when 'debian'
  package %w(
    apache2
    php
    libapache2-mod-php
    build-essential
    libgd-dev
    libssl-dev
    unzip
  )
when 'rhel', 'fedora'
  package %w(
    httpd
    php
    php-cli
    gcc
    glibc
    glibc-common
    gd
    gd-devel
    make
    net-snmp
    openssl-devel
    unzip
  )
else
  raise "Unsupported platform family: #{node['platform_family']}. This cookbook supports debian and rhel families."
end

group node['nagios']['group']

user node['nagios']['user'] do
  group node['nagios']['group']
  shell '/bin/bash'
  manage_home true
end

# Web server user varies by platform
web_user = case node['platform_family']
           when 'debian'
             'www-data'
           when 'rhel', 'fedora'
             'apache'
           else
             'www-data'
           end

group node['nagios']['cmd_group'] do
  members [node['nagios']['user'], web_user]
  append true
end

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

# Install NRPE plugin for check_nrpe command
remote_file "#{node['nagios']['src_dir']}/nrpe.tar.gz" do
  source "https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-#{node['nagios']['nrpe_version']}/nrpe-#{node['nagios']['nrpe_version']}.tar.gz"
  not_if { ::File.exist?("#{node['nagios']['install_dir']}/libexec/check_nrpe") }
end

execute 'compile_nrpe' do
  cwd node['nagios']['src_dir']
  command <<-EOH
    tar xzf nrpe.tar.gz
    cd nrpe-#{node['nagios']['nrpe_version']}
    ./configure --with-nagios-user=#{node['nagios']['user']} --with-nagios-group=#{node['nagios']['group']}
    make check_nrpe
    make install-plugin
  EOH
  not_if { ::File.exist?("#{node['nagios']['install_dir']}/libexec/check_nrpe") }
end
