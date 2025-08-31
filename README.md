# Chef Configuration Management

Chef cookbooks, recipes, and configuration management for infrastructure automation.

## Structure

- `cookbooks/` - Chef cookbooks and recipes
- `data_bags/` - Data bags for configuration data
- `environments/` - Environment-specific configurations  
- `roles/` - Role definitions and run lists
- `policyfiles/` - Policyfile configurations (Chef 12+)
- `scripts/` - Bootstrap and deployment scripts

## Usage

```bash
# Bootstrap a node
knife bootstrap <node-ip> -x <username> -P <password> --sudo

# Upload cookbooks
knife cookbook upload <cookbook-name>

# Run Chef Client
chef-client
```

## Key Files

- `knife.rb` - Knife configuration
- `client.rb` - Chef client configuration  
- `Berksfile` - Cookbook dependency management
- `Policyfile.rb` - Policy-based configuration

## Examples

- `cookbooks/webserver/` - Apache/Nginx web server setup
- `cookbooks/database/` - MySQL/PostgreSQL database configuration
- `cookbooks/monitoring/` - Monitoring stack deployment