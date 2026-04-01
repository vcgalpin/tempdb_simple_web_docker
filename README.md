## `README.md`


# tempdb_simple_web

This repo contains a simple Docker setup for running the Links web application in a single container.

The container includes:

- the Links web app
- PostgreSQL
- the application code cloned from GitHub at build time

The image is available at https://hub.docker.com/repository/docker/vcgalpin/xps_dcc_app/

To run this image, use
```
docker run -d \
  --name tempdb_simple_web \
  -p 8080:8080 \
  -v tempdb_simple_web_pgdata:/opt/postgres-data \
  vcgalpin/xps_dcc_app:tempdb_simple_web_test
```

## What it does

When the container starts, it:

1. starts PostgreSQL
2. creates the database role if needed
3. creates the database if needed
4. loads the SQL dump if the database does not already exist
5. starts the Links web app

## Important behaviour

### Rebuilds are manual
When the code changes on GitHub, the user decides whether to rebuild.

The `run-web.sh` script asks:

```text
Rebuild image from GitHub before starting? [y/N]
```

- answer `y` to rebuild from GitHub
- answer `n` to use the existing image/container

### Database persistence
The PostgreSQL data is stored in a Docker volume:

```text
tempdb_simple_web_pgdata
```

That means:

- rebuilding the image does not automatically delete the database
- the SQL dump is only loaded the first time the database is created

## Files

This setup uses:

- `Dockerfile`
- `entrypoint.sh`
- `run-web.sh`

## Requirements

You need:

- Docker

## First-time setup

Make the scripts executable:

```bash
chmod +x entrypoint.sh run-web.sh
```


## Starting the web app

Run:

```bash
./run-web.sh
```

You will be asked:

```text
Rebuild image from GitHub before starting? [y/N]
```

If no image exists yet, it will be built automatically.

Then open:

- <http://localhost:8080>

## What happens on first run

On the first run, the script will:

- build the Docker image if needed
- create the container
- create the PostgreSQL data volume
- start PostgreSQL
- create the database
- import the SQL dump
- start the Links web app

## What happens on later runs

### If you answer `n`
The script will:

- reuse the existing image
- reuse the existing container if possible
- reuse the existing database volume

### If you answer `y`
The script will:

- rebuild the image from GitHub
- remove the old container
- create a new container
- keep the existing database volume unless you delete it yourself

## Resetting the database

If you want a completely fresh database, remove:

- the container
- the PostgreSQL volume

Run:

```bash
docker rm -f tempdb_simple_web
docker volume rm tempdb_simple_web_pgdata
```

Then start again:

```bash
./run-web.sh
```

That will recreate the database from the SQL dump.

## Useful commands

### View logs

```bash
docker logs -f tempdb_simple_web
```

### Stop the container

```bash
docker stop tempdb_simple_web
```

### Start the container again

```bash
docker start tempdb_simple_web
```

### Remove the container

```bash
docker rm -f tempdb_simple_web
```

### Remove the database volume

```bash
docker volume rm tempdb_simple_web_pgdata
```

## Notes

### GitHub source
The application code is cloned from GitHub during the Docker build.

### Database settings
The default settings are:

- database: `linksdb`
- user: `linksuser`
- password: `change_me`

If you want to change them, edit `run-web.sh`.

### Links executable
The Links executable is `linx` not `links`.

