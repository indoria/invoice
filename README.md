# invoice

## Procedure
```
# Ensure that ports 3000 and 5432 are open, and not listed in PORTS tab of VS code console.
docker compose up -d
bash bin/setup.sh
```


## Help and Description
```
# If in compose commands "no configuration file provided" error occurs, then docker compose -f .devcontainer/docker-compose.yml

docker compose up -d
docker compose ps || docker ps [has an -a --all flag]

docker compose start
docker compose restart
docker compose stop

docker compose start db
docker compose restart db
docker compose stop db

docker container list || docker container ls [has an -a --all flag]

# Enter and exit db container
docker compose exec db /bin/bash
su postgres
docker compose exec -u postgres db psql || docker compose exec db psql -U codespace -d mydatabase
exit

# Run commands in container
docker compose exec -u postgres db pg_ctl status
```