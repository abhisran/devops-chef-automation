# Add Grafana GPG key
directory '/etc/apt/keyrings' do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
end

execute 'add-grafana-gpg-key' do
  command 'wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor > /etc/apt/keyrings/grafana.gpg'
  not_if { ::File.exist?('/etc/apt/keyrings/grafana.gpg') }
end

file '/etc/apt/sources.list.d/grafana.list' do
  content "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main\n"
  owner 'root'
  group 'root'
  mode '0644'
  notifies :update, 'apt_update[grafana-repo]', :immediately
end

apt_update 'grafana-repo' do
  action :nothing
end

apt_package 'grafana' do
  action :install
end
