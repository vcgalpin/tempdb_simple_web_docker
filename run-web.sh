#!/bin/sh
set -eu

IMAGE_NAME=tempdb_simple_web
CONTAINER_NAME=tempdb_simple_web
VOLUME_NAME=tempdb_simple_web_pgdata
PORT=8080

APP_REPO_URL=https://github.com/vcgalpin/xps_dcc_app
APP_REPO_BRANCH=main

POSTGRES_DB=linksdb
POSTGRES_USER=linksuser
POSTGRES_PASSWORD=change_me

APP_START_COMMAND='linx --config=config.0.9.8 src/startXPS.links'

printf "Rebuild image from GitHub before starting? [y/N] "
read REBUILD

case "${REBUILD:-}" in
  y|Y)
    echo "Rebuilding image..."
    docker build --no-cache \
      --build-arg APP_REPO_URL="${APP_REPO_URL}" \
      --build-arg APP_REPO_BRANCH="${APP_REPO_BRANCH}" \
      -t "${IMAGE_NAME}" .

    echo "Removing old container if it exists..."
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
    ;;
  *)
    ;;
esac

if docker container inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
  RUNNING=$(docker inspect -f '{{.State.Running}}' "${CONTAINER_NAME}")

  if [ "${RUNNING}" = "true" ]; then
    echo "Container is already running."
    echo "Open http://localhost:${PORT}"
    exit 0
  fi

  echo "Starting existing container..."
  docker start "${CONTAINER_NAME}" >/dev/null
  echo "Open http://localhost:${PORT}"
  exit 0
fi

if ! docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
  echo "Image does not exist yet, building it now..."
  docker build --no-cache \
    --build-arg APP_REPO_URL="${APP_REPO_URL}" \
    --build-arg APP_REPO_BRANCH="${APP_REPO_BRANCH}" \
    -t "${IMAGE_NAME}" .
fi

echo "Creating and starting container..."
docker run -d \
  --name "${CONTAINER_NAME}" \
  -p "${PORT}:8080" \
  -v "${VOLUME_NAME}:/opt/postgres-data" \
  -e POSTGRES_DB="${POSTGRES_DB}" \
  -e POSTGRES_USER="${POSTGRES_USER}" \
  -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
  -e APP_START_COMMAND="${APP_START_COMMAND}" \
  "${IMAGE_NAME}" >/dev/null

echo "Container started."
echo "Open http://localhost:${PORT}"

