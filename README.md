## `README.md`


# tempdb_simple_web

This repo contains a simple Docker setup for running the [Links temporal DB web application](https://github.com/vcgalpin/xps_dcc_app) in a single container.

The container includes the Links web app, the application code cloned from GitHub at build time and PostgreSQL.

The container provides a link to the app at <http://localhost:8080>

There are two different ways to run this container from an image.
1. **Build the image** yourself on your own computer using the Dockerfile, 
    + *either* run the bash script - [more details on what the script does](#running-the-bash-script)
      ```
      ./run-web.sh
      ```
    + *or* use the following command
      ```
      docker build --no-cache \
      --build-arg APP_REPO_URL="https://github.com/vcgalpin/xps_dcc_app" \
      --build-arg APP_REPO_BRANCH="main" \
      -t tempdb-simple-web .
      ```
    + *or* import a .dockerbuild file into Docker Desktop (more details to follow).
      
1. **Download the image** and run it. The image created by this setup is available at https://hub.docker.com/repository/docker/vcgalpin/xps_dcc_app/

   To run this image as a container,
      + *either* use 
        ```
        docker run -d \
        --name tempdb_simple_web \
        -p 8080:8080 \
        -v tempdb_simple_web_pgdata:/opt/postgres-data \
        vcgalpin/xps_dcc_app:tempdb_simple_web_test
        ```
        and to stop and restart it or to view the logs, use
        ```
        docker stop tempdb_simple_web
        docker start tempdb_simple_web
        docker logs -f tempdb_simple_web
        ```
      + *or* if the image is available in Docker Desktop, it can be run by supplying the appropriate port information and volume information (more details to follow).
   
   (Note: This image does *not* provide the functionality of `run-web.sh`. This functionality can only be accessed when building the image from the Dockerfile rather than just running the downloaded image as a container.)

## What the container does

When the container starts, it:

1. starts PostgreSQL
2. creates the database role if needed
3. creates the database if needed
4. loads the SQL dump if the database does not already exist
5. starts the Links web app


### Database persistence and refresh
The PostgreSQL data is stored in a Docker volume:

```text
tempdb_simple_web_pgdata
```

That means:

- rebuilding the image does not automatically delete the database
- the SQL dump is only loaded the first time the database is created

If you want a completely fresh database, remove the container and the PostgreSQL volume. Run

```bash
docker rm -f tempdb_simple_web
docker volume rm tempdb_simple_web_pgdata
```

## Running the bash script

Run `./run-web.sh` (making the script executable if necessary: ```chmod +x entrypoint.sh run-web.sh```) 

You will be asked:

```text
Rebuild image from GitHub before starting? [y/N]
```

If no image exists yet, it will be built automatically.

Then open <http://localhost:8080>

### What happens on first run of the bash script

On the first run, the script will:

- build the Docker image if needed
- create the container
- create the PostgreSQL data volume
- start PostgreSQL
- create the database
- import the SQL dump
- start the Links web app

### What happens on later runs

#### If you answer `n`
The script will:

- reuse the existing image
- reuse the existing container if possible
- reuse the existing database volume

#### If you answer `y`
The script will:

- rebuild the image from GitHub
- remove the old container
- create a new container
- keep the existing database volume unless you delete it yourself
