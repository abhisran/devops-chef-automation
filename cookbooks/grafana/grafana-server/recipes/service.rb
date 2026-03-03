service 'grafana-server' do
  supports restart: true, status: true, reload: false
  action [:enable, :start]
end
