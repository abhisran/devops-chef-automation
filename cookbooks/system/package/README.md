# System Package Cookbook

> **Author:** Abhishek Ranjan
> **Cookbook:** `package`
> **Last Updated:** 2025

---

## Overview

The `package` cookbook is a core utility that ensures essential system tools are installed on every node in the infrastructure. It handles APT cache updates and installs a baseline set of packages required for administration and service operation.

**Key facts:**
- Updates APT cache on every run
- Installs 6+ essential admin tools (curl, git, nvim, etc.)
- **Mandatory:** Should be the first recipe in every node's run list
- Ensures `conntrack` is present for Kubernetes nodes

---

## Infrastructure Details

| Category | Value |
|-----------|-------|
| **Platforms** | Ubuntu 22.04+, Debian 11+ |
| **Package Manager** | APT |
| **Execution Order** | Run List Priority 1 |

---

## Essential Packages

The following tools are installed by default:

| Package | Purpose |
|---------|---------|
| `curl` | HTTP client for APIs and downloads |
| `git` | Version control for Jenkins and Chef |
| `neovim` | Modern text editor for server config |
| `net-tools` | Network utilities (`ifconfig`, `netstat`) |
| `wget` | File downloader |
| `conntrack` | **Required for Kubernetes** |

---

## Recipes

### default
Updates the APT cache and installs the core package list.

---

## Usage

### Install & Upload

```bash
cd system/package
berks install && berks upload
```

### Assign to Node

Add `package` to the **top** of your node's run list:

```ruby
run_list [
  'recipe[package]',
  'recipe[firewall]',
  'recipe[k8s-master]'
]
```

## License

All Rights Reserved

## Author

Abhishek Ranjan
