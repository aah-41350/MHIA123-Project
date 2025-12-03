#!/bin/bash
# Connect to PostgreSQL on your NAS via Tailscale

PG_HOST="100.101.3.39"   # Replace with your NAS Tailnet IP
PG_USER="postgres"
PG_DB="mimiciv"
PG_PORT="5432"

echo "Connecting to PostgreSQL at $PG_HOST ..."
psql -h "$PG_HOST" -U "$PG_USER" -d "$PG_DB" -p "$PG_PORT"
