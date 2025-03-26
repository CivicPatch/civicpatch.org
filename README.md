# README

## Deployment

### Requirements

#### Add Places

```bash
#Update open data source
bundle exec rake 'update_open_data:sync' 

# Set up "places" table if none exists; adds state places -- use only once per state
bundle exec rake 'sync_map:sync[place,wa]'

# Add city people for state
bundle exec rake 'sync_cities:sync[wa]'
```

### Deploying

## Server Hardening
- [ ] Install fail2ban
```bash
sudo apt-get update
sudo apt-get install fail2ban
sudo systemctl status fail2ban.service
cd /etc/fail2ban
head -20 jail.conf
```
- [ ] Install and configure UFW
