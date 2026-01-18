resource_name :containerd_config
provides :containerd_config
unified_mode true

property :config_path, String, default: '/etc/containerd/config.toml'
property :systemd_cgroup, [true, false], default: true

action :create do
  template new_resource.config_path do
    source 'containerd_config.toml.erb'
    variables(
      systemd_cgroup: new_resource.systemd_cgroup
    )
    notifies :restart, 'service[containerd]', :immediately
  end
end
