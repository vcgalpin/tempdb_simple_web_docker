#!/bin/sh
set -eu

export PATH="/usr/lib/postgresql/16/bin:${PATH}"
export OPAMSWITCH="${OPAMSWITCH:-5.1.1}"

export PGDATA=/opt/postgres-data
export PGPORT=5432
export PGSOCKETDIR=/tmp

POSTGRES_DB="${POSTGRES_DB:-linksdb}"
POSTGRES_USER="${POSTGRES_USER:-linksuser}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-change_me}"

APP_DIR=/opt/app
DUMP_FILE=/opt/app/sql/xps_dcc_app.sql

mkdir -p "${PGDATA}" "${PGSOCKETDIR}"

if [ ! -f "${DUMP_FILE}" ]; then
  echo "SQL dump not found: ${DUMP_FILE}"
  exit 1
fi

if [ ! -s "${PGDATA}/PG_VERSION" ]; then
  echo "Initialising PostgreSQL data directory..."
  initdb -D "${PGDATA}" --encoding=UTF8 --locale=en_US.UTF-8
fi

echo "Starting PostgreSQL..."
pg_ctl -D "${PGDATA}" -l "${PGDATA}/postgres.log" -o "-p ${PGPORT} -k ${PGSOCKETDIR}" start

echo "Waiting for PostgreSQL..."
until pg_isready -h "${PGSOCKETDIR}" -p "${PGPORT}" >/dev/null 2>&1
do
  sleep 1
done

echo "PostgreSQL is ready."

ROLE_EXISTS=$(psql -h "${PGSOCKETDIR}" -p "${PGPORT}" -d postgres -tAc \
  "SELECT 1 FROM pg_roles WHERE rolname='${POSTGRES_USER}'" || true)

if [ "${ROLE_EXISTS}" != "1" ]; then
  echo "Creating role ${POSTGRES_USER}..."
  psql -h "${PGSOCKETDIR}" -p "${PGPORT}" -d postgres -v ON_ERROR_STOP=1 -c \
    "CREATE ROLE ${POSTGRES_USER} LOGIN PASSWORD '${POSTGRES_PASSWORD}';"
fi

DB_EXISTS=$(psql -h "${PGSOCKETDIR}" -p "${PGPORT}" -d postgres -tAc \
  "SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB}'" || true)

if [ "${DB_EXISTS}" != "1" ]; then
  echo "Creating database ${POSTGRES_DB}..."
  psql -h "${PGSOCKETDIR}" -p "${PGPORT}" -d postgres -v ON_ERROR_STOP=1 -c \
    "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};"

  echo "Loading SQL dump..."
  psql -h "${PGSOCKETDIR}" -p "${PGPORT}" -d "${POSTGRES_DB}" -v ON_ERROR_STOP=1 -f "${DUMP_FILE}"
fi

cd "${APP_DIR}"

export PGHOST="${PGSOCKETDIR}"
export PGDATABASE="${POSTGRES_DB}"
export PGUSER="${POSTGRES_USER}"
export PGPASSWORD="${POSTGRES_PASSWORD}"

echo "Starting Links web app..."
exec opam exec --switch="${OPAMSWITCH}" -- sh -c "${APP_START_COMMAND}"

