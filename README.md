# README

## Deployment

### Setup

```bash
docker compose build

docker compose up -d

```

App should be up at [http://localhost:3000](http://localhost:3000)

### Commands

* Update open data source (optional) -- this will pull in data from open-data
`docker exec -it civicpatch_web bundle exec rake 'od:sync'`
