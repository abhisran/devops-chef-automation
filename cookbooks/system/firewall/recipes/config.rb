#
# Cookbook:: firewall
# Recipe:: config
#
# Copyright:: 2025, The Authors, All Rights Reserved.

# Set default policies
execute 'ufw-default-incoming' do
  command "ufw default #{node['firewall']['default_policy_incoming']} incoming"
  not_if "ufw status verbose | grep -q 'Default: #{node['firewall']['default_policy_incoming']} (incoming)'"
end

execute 'ufw-default-outgoing' do
  command "ufw default #{node['firewall']['default_policy_outgoing']} outgoing"
  not_if "ufw status verbose | grep -q '#{node['firewall']['default_policy_outgoing']} (outgoing)'"
end

execute 'ufw-default-routed' do
  command "ufw default #{node['firewall']['default_policy_routed']} routed"
  not_if "ufw status verbose | grep -q '#{node['firewall']['default_policy_routed']} (routed)'"
end

execute 'ufw-logging' do
  command "ufw logging #{node['firewall']['logging']}"
  not_if "ufw status verbose | grep -qi 'Logging: .*#{node['firewall']['logging']}'"
end

# Always apply SSH rule first — safety net before enabling UFW
execute 'ufw-allow-ssh-safety' do
  command "ufw allow 22/tcp comment 'SSH access'"
  not_if "ufw status | grep -qw '22/tcp'"
end

# Apply all enabled rule groups
node['firewall']['rule_groups'].each do |group_name, group|
  next unless group['enabled']

  group['rules'].each do |rule_name, rule|
    resource_name = "ufw-#{group_name}-#{rule_name}"
    port = rule['port']
    protocol = rule['protocol']
    action = rule['action']
    source = rule['source']
    comment = rule['comment'] || "#{group_name}/#{rule_name}"

    if source
      ufw_cmd = "ufw #{action} from #{source} to any port #{port} proto #{protocol} comment '#{comment}'"
      guard_cmd = "ufw status | grep -q '#{port}/#{protocol}.*#{source}'"
    else
      ufw_cmd = "ufw #{action} #{port}/#{protocol} comment '#{comment}'"
      guard_cmd = "ufw status | grep -qw '#{port}/#{protocol}'"
    end

    execute resource_name do
      command ufw_cmd
      not_if guard_cmd
    end
  end
end

# Kubernetes nodes require IP forwarding and bridge-nf-call for pod networking.
# When UFW is enabled, its default FORWARD policy (DROP) blocks pod-to-pod
# traffic across nodes. Override it to ACCEPT on K8s nodes.
k8s_enabled = node['firewall']['rule_groups'].any? do |name, group|
  %w(k8s_master k8s_worker).include?(name) && group['enabled']
end

if k8s_enabled
  execute 'ufw-forward-policy-accept' do
    command "sed -i 's/^DEFAULT_FORWARD_POLICY=.*$/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/' /etc/default/ufw"
    only_if "grep -q 'DEFAULT_FORWARD_POLICY=\"DROP\"' /etc/default/ufw"
    notifies :run, 'execute[ufw-reload]', :delayed
  end

  execute 'ufw-sysctl-ip-forward' do
    command "sed -i 's|^#\?net/ipv4/ip_forward=.*|net/ipv4/ip_forward=1|' /etc/ufw/sysctl.conf"
    not_if "grep -q '^net/ipv4/ip_forward=1' /etc/ufw/sysctl.conf"
    notifies :run, 'execute[ufw-reload]', :delayed
  end

  execute 'ufw-sysctl-bridge-nf-call' do
    command <<-EOH
      if grep -q 'net/bridge/bridge-nf-call-iptables' /etc/ufw/sysctl.conf; then
        sed -i 's|^#\?net/bridge/bridge-nf-call-iptables=.*|net/bridge/bridge-nf-call-iptables=1|' /etc/ufw/sysctl.conf
      else
        echo 'net/bridge/bridge-nf-call-iptables=1' >> /etc/ufw/sysctl.conf
      fi
    EOH
    not_if "grep -q '^net/bridge/bridge-nf-call-iptables=1' /etc/ufw/sysctl.conf"
    notifies :run, 'execute[ufw-reload]', :delayed
  end
end

execute 'ufw-reload' do
  command 'ufw --force reload'
  action :nothing
end
