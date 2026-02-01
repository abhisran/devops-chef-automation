service 'nagios' do
  action [:enable, :start]
end

service 'apache2' do
  action [:enable, :start]
end

