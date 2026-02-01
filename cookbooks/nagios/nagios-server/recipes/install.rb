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
    apache2-utils
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
    httpd-tools
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
    make install-webconf
  EOH
  not_if { ::File.exist?("#{node['nagios']['install_dir']}/bin/nagios") }
end

# Install webconf separately to handle existing installations
execute 'install_webconf' do
  cwd "#{node['nagios']['src_dir']}/nagios-#{node['nagios']['version']}"
  command 'make install-webconf'
  only_if { ::Dir.exist?("#{node['nagios']['src_dir']}/nagios-#{node['nagios']['version']}") }
  not_if { ::File.exist?('/etc/apache2/sites-enabled/nagios.conf') || ::File.exist?('/etc/httpd/conf.d/nagios.conf') }
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

# Enable Apache CGI module for Nagios web interface
case node['platform_family']
when 'debian'
  execute 'enable_apache_cgi' do
    command 'a2enmod cgi rewrite'
    not_if 'apache2ctl -M 2>/dev/null | grep -q cgi_module'
    notifies :restart, 'service[apache2]', :delayed
  end
when 'rhel', 'fedora'
  # CGI module is typically enabled by default on RHEL
  execute 'enable_apache_cgi' do
    command 'echo "LoadModule cgi_module modules/mod_cgi.so" >> /etc/httpd/conf.modules.d/00-cgi.conf'
    not_if { ::File.exist?('/etc/httpd/conf.modules.d/00-cgi.conf') }
    notifies :restart, 'service[httpd]', :delayed
  end
end

# Create htpasswd file for Nagios web UI authentication
execute 'create_nagios_htpasswd' do
  command "echo '#{node['nagios']['admin_password']}' | htpasswd -ci #{node['nagios']['install_dir']}/etc/htpasswd.users #{node['nagios']['admin_user']}"
  creates "#{node['nagios']['install_dir']}/etc/htpasswd.users"
  sensitive true
end

file "#{node['nagios']['install_dir']}/etc/htpasswd.users" do
  owner node['nagios']['user']
  group node['nagios']['group']
  mode '0640'
end
