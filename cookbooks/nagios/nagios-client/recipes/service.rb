# NRPE service name varies by platform
nrpe_service = case node['platform_family']
               when 'debian'
                 'nagios-nrpe-server'
               when 'rhel', 'fedora'
                 'nrpe'
               else
                 'nagios-nrpe-server'
               end

service 'nrpe' do
  service_name nrpe_service
  supports restart: true, status: true, reload: true
  action [:enable, :start]
end
