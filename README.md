## `README.md`


# tempdb_simple_web

This repo contains a simple Docker setup for running the Links web application in a single container.

The container includes:

- the Links web app
- PostgreSQL
- the application code cloned from GitHub at build time

There are two different ways to run this container from an image.
1. **Build the image** yourself on your own computer using the Dockerfile. This is supported by the bash script `run-web-shell.sh` or you can use
   ```
     docker build --no-cache \
    --build-arg APP_REPO_URL="https://github.com/vcgalpin/xps_dcc_app" \
    --build-arg APP_REPO_BRANCH="main" \
    -t tempdb-web-shell .
   ```
1. **Download the image** and run it. The image created by this setup is available at https://hub.docker.com/repository/docker/vcgalpin/xps_dcc_app/

   To run this image as a container, use
   ```
   docker run -d \
    --name tempdb_simple_web \
    -p 8080:8080 \
    -v tempdb_simple_web_pgdata:/opt/postgres-data \
    vcgalpin/xps_dcc_app:tempdb_simple_web_test
   ```
   and to stop and restart it, use
   ```
   docker stop tempdb_simple_web
   docker start tempdb_simple_web
   ```
   **Note:** This image does *not* provide the functionality of `run-web.sh`. This functionality can only be accessed when building the image from the Dockerfile rather than just running    the downloaded image as a container.

## What it does

When the container starts, it:

1. starts PostgreSQL
2. creates the database role if needed
3. creates the database if needed
4. loads the SQL dump if the database does not already exist
5. starts the Links web app


### Database persistence
The PostgreSQL data is stored in a Docker volume:

```text
tempdb_simple_web_pgdata
```

That means:

- rebuilding the image does not automatically delete the database
- the SQL dump is only loaded the first time the database is created
  

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

## Files

This setup uses:

- `Dockerfile`
- `entrypoint.sh`
- `run-web.sh`


