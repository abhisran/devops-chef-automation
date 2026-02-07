#
# Cookbook:: jenkins-agent
# Recipe:: service
#
# Copyright:: 2025, The Authors, All Rights Reserved.

service 'ssh' do
  supports restart: true, status: true
  action [:enable, :start]
end

log 'jenkins_agent_ready' do
  message 'Jenkins SSH agent is ready. Configure the Jenkins server to connect to this node via SSH.'
  level :info
end
