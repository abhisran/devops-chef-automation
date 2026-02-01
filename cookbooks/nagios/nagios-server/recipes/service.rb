service 'nagios' do
  supports reload: true, restart: true, status: true
  action [:enable, :start]
end

# Web service name varies by platform
web_service = node['platform_family'] == 'debian' ? 'apache2' : 'httpd'

service web_service do
  supports reload: true, restart: true, status: true
  action [:enable, :start]
end

