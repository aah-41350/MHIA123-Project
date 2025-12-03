#!/bin/bash

PG_HOST="100.101.9.39"
PG_USER="postgres"
PG_DB="mydb"
PG_PORT="5432"

echo "Connecting via Tailscale SOCKS5 tunnel..."
proxychains4 psql -h "$PG_HOST" -U "$PG_USER" -d "$PG_DB" -p "$PG_PORT"
