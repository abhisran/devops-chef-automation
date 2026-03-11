#
# Cookbook:: jenkins-agent
# Recipe:: aws_cli
#
# Copyright:: 2025, The Authors, All Rights Reserved.

return unless node['jenkins']['agent']['aws_cli']['enabled']

# Install dependencies
package %w(curl unzip)

# AWS CLI v2 installation
remote_file '/tmp/awscliv2.zip' do
  source 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip'
  mode '0644'
  not_if { ::File.exist?('/usr/local/bin/aws') }
end

execute 'install_aws_cli' do
  command 'unzip /tmp/awscliv2.zip -d /tmp && /tmp/aws/install && rm -rf /tmp/aws /tmp/awscliv2.zip'
  creates '/usr/local/bin/aws'
  only_if { ::File.exist?('/tmp/awscliv2.zip') }
end
