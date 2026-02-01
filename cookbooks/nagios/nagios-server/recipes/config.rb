template "#{node['nagios']['install_dir']}/etc/objects/nrpe_commands.cfg" do
  source 'nrpe_commands.cfg.erb'
  owner node['nagios']['user']
  group node['nagios']['group']
  mode '0644'
  notifies :reload, 'service[nagios]', :delayed
end

template "#{node['nagios']['install_dir']}/etc/objects/hosts.cfg" do
  source 'hosts.cfg.erb'
  owner node['nagios']['user']
  group node['nagios']['group']
  mode '0644'
  notifies :reload, 'service[nagios]', :delayed
end

# Append cfg_file entries for our custom config files
execute 'add nrpe_commands cfg entry' do
  command "echo 'cfg_file=#{node['nagios']['install_dir']}/etc/objects/nrpe_commands.cfg' >> #{node['nagios']['install_dir']}/etc/nagios.cfg"
  not_if "grep -q '^cfg_file=#{node['nagios']['install_dir']}/etc/objects/nrpe_commands.cfg$' #{node['nagios']['install_dir']}/etc/nagios.cfg"
  notifies :reload, 'service[nagios]', :delayed
end

execute 'add hosts cfg entry' do
  command "echo 'cfg_file=#{node['nagios']['install_dir']}/etc/objects/hosts.cfg' >> #{node['nagios']['install_dir']}/etc/nagios.cfg"
  not_if "grep -q '^cfg_file=#{node['nagios']['install_dir']}/etc/objects/hosts.cfg$' #{node['nagios']['install_dir']}/etc/nagios.cfg"
  notifies :reload, 'service[nagios]', :delayed
end
