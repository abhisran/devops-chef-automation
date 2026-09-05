name 'k8s-worker'
maintainer 'Abhishek Ranjan'
maintainer_email 'abhisran6@gmail.com'
license 'All Rights Reserved'
description 'Installs/Configures Kubernetes worker node'
version '0.1.3'
chef_version '>= 16.0'

depends 'chef-vault', '~> 4.0'
depends 'firewall'
depends 'apt'
depends 'package'
depends 'nagios-client'
depends 'prometheus-client'
depends 'nfs-client'

# NOTE: apt_update is a built-in resource in Chef 16+, no apt cookbook needed
