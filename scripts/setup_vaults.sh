#!/bin/bash
#
# Chef Vault & Data Bag Setup Script
# Run this from your workstation (Mac) after Chef Server is configured,
# knife.rb is set up at ~/.chef/knife.rb, AND nodes are bootstrapped
# (registered with Chef Server via chef-client first run).
#
# Workflow:
#   1. Set up Chef Server (Ansible chef.yml --tags server)
#   2. Bootstrap clients (Ansible chef.yml --tags client)
#   3. Run this script to create vaults
#   4. Upload cookbooks (knife cookbook upload)
#   5. Run chef-client on nodes
#
# Usage: ./setup_vaults.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_DIR="${HOME}/.chef"
ADMIN_USER="aranjan"

JENKINS_CLIENTS="jenkins-server,jenkins-agent"
K8S_CLIENTS="master-node,worker-node-1,worker-node-2"
NAGIOS_SERVER_CLIENT="nagios-server"

echo "============================================"
echo "  Chef Vault & Data Bag Setup"
echo "============================================"
echo ""

# -----------------------------------------------
# 1. Generate Jenkins SSH key pair
# -----------------------------------------------
echo "[1/4] Generating Jenkins SSH key pair..."

if [ ! -f "${KEY_DIR}/jenkins_agent_key" ]; then
  ssh-keygen -t ed25519 -f "${KEY_DIR}/jenkins_agent_key" -N "" -C "jenkins-agent-ssh-key"
  echo "  ✓ SSH key pair generated at ${KEY_DIR}/jenkins_agent_key"
else
  echo "  ⊘ SSH key pair already exists at ${KEY_DIR}/jenkins_agent_key (skipping)"
fi

# -----------------------------------------------
# 2. Create Jenkins Credentials Vault
# -----------------------------------------------
echo ""
echo "[2/4] Creating Jenkins credentials vault (jenkins_credentials/ssh_keys)..."

# Create temporary JSON for the vault item
TMPFILE=$(mktemp)
cat > "${TMPFILE}" <<EOF
{
  "id": "ssh_keys",
  "private_key": $(ruby -rjson -e "print JSON.generate(File.read('${KEY_DIR}/jenkins_agent_key'))"),
  "public_key": $(ruby -rjson -e "print JSON.generate(File.read('${KEY_DIR}/jenkins_agent_key.pub').strip())")
}
EOF

# Delete existing vault if present (handles broken/corrupt vaults from previous runs)
knife vault delete jenkins_credentials ssh_keys -y --mode client 2>/dev/null || true
knife data bag delete jenkins_credentials -y 2>/dev/null || true

knife vault create jenkins_credentials ssh_keys \
  --json "${TMPFILE}" \
  --search "name:${JENKINS_CLIENTS//,/ OR name:}" \
  --admins "${ADMIN_USER}" \
  --mode client

rm -f "${TMPFILE}"
echo "  ✓ jenkins_credentials/ssh_keys vault created"

# -----------------------------------------------
# 3. Create Nagios Credentials Vault
# -----------------------------------------------
echo ""
echo "[3/4] Creating Nagios credentials vault (nagios_credentials/admin_password)..."

read -sp "  Enter Nagios admin password (nagiosadmin): " NAGIOS_PASSWORD
echo ""

TMPFILE=$(mktemp)
cat > "${TMPFILE}" <<EOF
{
  "id": "admin_password",
  "password": "${NAGIOS_PASSWORD}"
}
EOF

knife vault delete nagios_credentials admin_password -y --mode client 2>/dev/null || true
knife data bag delete nagios_credentials -y 2>/dev/null || true

knife vault create nagios_credentials admin_password \
  --json "${TMPFILE}" \
  --search "name:${NAGIOS_SERVER_CLIENT}" \
  --admins "${ADMIN_USER}" \
  --mode client

rm -f "${TMPFILE}"
echo "  ✓ nagios_credentials/admin_password vault created"

# -----------------------------------------------
# 4. Create App Versions Data Bag (non-sensitive, no encryption needed)
# -----------------------------------------------
echo ""
echo "[4/4] Creating app_versions data bag (centralized version management)..."

# Create temporary JSON for the data bag (must end in .json for knife)
TMPFILE=$(mktemp /tmp/app_versions.XXXXXX.json)
cat > "${TMPFILE}" <<'EOF'
{
  "id": "default",
  "jenkins": {
    "java_package": "openjdk-21-jre",
    "plugin_manager_version": "2.13.0",
    "kubectl_version": "1.33"
  },
  "kubernetes": {
    "version": "1.33",
    "cni_version": "1.4.0"
  },
  "nagios": {
    "version": "4.5.11",
    "nrpe_version": "4.1.0"
  },
  "prometheus": {
    "server_version": "2.53.3",
    "node_exporter_version": "1.8.2"
  }
}
EOF

knife data bag delete app_versions -y 2>/dev/null || true
knife data bag create app_versions
knife data bag from file app_versions "${TMPFILE}"

rm -f "${TMPFILE}"
echo "  ✓ app_versions/default data bag created"

# -----------------------------------------------
# Summary
# -----------------------------------------------
echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "Vaults created:"
echo "  • jenkins_credentials/ssh_keys    → Jenkins server + agent (encrypted)"
echo "  • nagios_credentials/admin_password → Nagios server (encrypted)"
echo "Data bags created:"
echo "  • app_versions/default            → All nodes (plain text)"
echo ""
echo "Verify with:"
echo "  knife vault list"
echo "  knife vault show jenkins_credentials ssh_keys --mode client"
echo "  knife vault show nagios_credentials admin_password --mode client"
echo "  knife data bag show app_versions default"
echo ""
echo "SSH keys saved at:"
echo "  Private: ~/.chef/jenkins_agent_key"
echo "  Public:  ~/.chef/jenkins_agent_key.pub"
echo ""
echo "IMPORTANT: The vault search queries use node names."
echo "Nodes must be bootstrapped (chef-client run) before they"
echo "can access vault items. If you add new nodes later, run:"
echo "  knife vault update <vault> <item> --search 'name:<new-node>'"
echo ""
echo "Next steps:"
echo "  1. Upload cookbooks:  knife cookbook upload --all --cookbook-path chef/cookbooks/*/"
echo "  2. Bootstrap clients: ansible-playbook playbooks/chef.yml --ask-vault-pass --tags client"
echo "  3. Run chef-client:   knife ssh 'name:*' 'sudo chef-client' -x aranjan"
