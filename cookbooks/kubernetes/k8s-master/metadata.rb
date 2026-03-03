name 'k8s-master'
maintainer 'Abhishek Ranjan'
maintainer_email 'abhisran6@gmail.com'
license 'All Rights Reserved'
description 'Installs/Configures Kubernetes master node'
version '0.1.3'
chef_version '>= 16.0'

depends 'chef-vault', '~> 4.0'
depends 'firewall'

# NOTE: apt_update is a built-in resource in Chef 16+, no apt cookbook needed
