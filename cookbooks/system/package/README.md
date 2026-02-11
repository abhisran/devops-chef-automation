# package Cookbook

Simple cookbook for installing essential system packages on all nodes.

## Requirements

### Platforms

- Debian/Ubuntu

### Chef

- Chef 16+

## What It Installs

Updates the apt package cache, then installs the following packages:

| Package | Purpose |
|---------|---------|
| `curl` | HTTP client |
| `git` | Version control |
| `neovim` | Text editor |
| `net-tools` | Network utilities (ifconfig, netstat, etc.) |
| `wget` | File downloader |
| `conntrack` | Connection tracking (required by Kubernetes) |

## Usage

Add the cookbook to your node's run list (typically before other cookbooks):

```ruby
run_list 'recipe[package]'
```

## Author

Abhishek Ranjan
