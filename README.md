# README

## Deployment

### Requirements
- docker
- mise (optional, only if you want to try running without docker)
  - There are also some scripts available under `mise.toml`

### Setup

- Tested with: Mac OSX, Windows & WSL2 (Ubuntu)
- Create `.env` file with command: `./script/setup-env.sh`
- Run commands:

```bash
docker compose build

docker compose up -d
```

App should be up at [http://localhost:3000](http://localhost:3000)

### Commands

- Update open data source (optional) -- this will pull in data from open-data
  `docker exec -it civicpatch_web bundle exec rake 'od:sync'`

- To populate the progress map with data, run:
  ```bash
  `bundle exec rake 'data:process'`
  ```