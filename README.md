# README

## Deployment

## Examples
* Seattle: http://127.0.0.1:3000/api/representatives?lat=47.606&long=-122.332
* Seattle by OCDID: https://civicpatch.org/api/representatives?ocd_id=ocd-division/country:us/state:wa/place:seattle
* Bremerton: http://127.0.0.1:3000/api/representatives?lat=47.5687&long=-122.6515
* http://127.0.0.1:3000/api/representatives?lat=47.658779.536&long=-117.426048

#### Add Places

```bash
#Update open data source
bundle exec rake 'od:sync' 

# Set up "places" table if none exists; adds state places -- use only once per state
bundle exec rake 'maps:sync[wa]'

# Add city people for state
bundle exec rake 'cities:sync'
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
