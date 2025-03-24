# README

## Deployment

### Requirements

#### Add Places

```bash
PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -d $POSTGRES_DB -h $POSTGRES_HOST

# First, ensure that the existing layer is cleared of duplicates if necessary
# You can run a SQL command to remove duplicates based on your criteria before running ogr2ogr

# Example SQL command to remove duplicates (customize as needed)
# psql -U $POSTGRES_USER -d $POSTGRES_DB -c "DELETE FROM places WHERE id NOT IN (SELECT MIN(id) FROM places GROUP BY unique_column);"

# Import data into a temporary table first

export SHAPEFILE_PATH=data/open-data/data/us/census/place_2024/tl_2024_53_place.shp

ogr2ogr \
  -f "PostgreSQL" \
  PG:"dbname=$POSTGRES_DB user=$POSTGRES_USER host=$POSTGRES_HOST password=$POSTGRES_PASSWORD port=5432" \
  $SHAPEFILE_PATH \
  -nln places \
  -nlt PROMOTE_TO_MULTI \
  -lco GEOMETRY_NAME=geom \
  -lco FID=gid \
  -lco PRECISION=NO \
  -append

PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -d $POSTGRES_DB -h $POSTGRES_HOST -c "DELETE FROM places WHERE gid NOT IN (SELECT MAX(gid) FROM places GROUP BY statefp, placefp);"


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
