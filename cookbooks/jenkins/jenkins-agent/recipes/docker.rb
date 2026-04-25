#
# Cookbook:: jenkins-agent
# Recipe:: docker
#
# Copyright:: 2025, The Authors, All Rights Reserved.

return unless node['jenkins']['agent']['docker']['enabled']

# Install prerequisites
package %w(ca-certificates curl gnupg lsb-release)

# Create keyrings directory
directory '/etc/apt/keyrings' do
  mode '0755'
  recursive true
end

# Add Docker GPG key
execute 'add-docker-gpg-key' do
  command 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && chmod a+r /etc/apt/keyrings/docker.gpg'
  creates '/etc/apt/keyrings/docker.gpg'
  live_stream false
end

# Map kernel architecture to dpkg architecture string used by Debian/Ubuntu
dpkg_arch = case node['kernel']['machine']
            when 'x86_64' then 'amd64'
            when 'aarch64' then 'arm64'
            when 'armv7l' then 'armhf'
            else 'amd64'
            end

# Add Docker repository
file '/etc/apt/sources.list.d/docker.list' do
  content "deb [arch=#{dpkg_arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu #{node['lsb']['codename']} stable\n"
  mode '0644'
  notifies :update, 'apt_update[update-after-docker-repo]', :immediately
end

apt_update 'update-after-docker-repo' do
  action :nothing
end

# Install Docker CE packages
node['jenkins']['agent']['docker']['packages'].each do |pkg|
  package pkg
end

# Add jenkins user to the docker group
group 'docker' do
  members [node['jenkins']['agent']['user']]
  append true
  action :manage
end

# Enable and start Docker service
service 'docker' do
  supports restart: true, status: true
  action [:enable, :start]
end
