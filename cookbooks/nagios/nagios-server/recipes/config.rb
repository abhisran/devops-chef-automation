template '/usr/local/nagios/etc/nagios.cfg' do
  source 'nagios.cfg.erb'
  owner 'nagios'
  group 'nagios'
  mode '0644'
  notifies :reload, 'service[nagios]'
end

template '/usr/local/nagios/etc/objects/commands.cfg' do
  source 'commands.cfg.erb'
  owner 'nagios'
  group 'nagios'
  mode '0644'
  notifies :reload, 'service[nagios]'
end
