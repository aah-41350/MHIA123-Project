#!/bin/sh

echo "==== Backing up existing configs ===="
docker exec -i pg-mimicdb sh -c "cp /var/lib/postgresql/18/main/pg_hba.conf /var/lib/postgresql/18/main/pg_hba.conf.bak"
docker exec -i pg-mimicdb sh -c "cp /var/lib/postgresql/18/main/postgresql.conf /var/lib/postgresql/18/main/postgresql.conf.bak"

echo "==== Installing new pg_hba.conf ===="
docker exec -i pg-mimicdb sh -c "cat > /var/lib/postgresql/18/main/pg_hba.conf << 'EOF'
# ===================================================================
# PostgreSQL Client Authentication Configuration
# Hardened for Docker + Tailscale Access Only
# ===================================================================

# Unix socket connections (internal)
local   all             all                                     trust
local   replication     all                                     trust

# Local TCP (needed due to Docker NAT rewriting all connections to 127.0.0.1)
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5

# Tailscale subnet (all Tailscale devices)
host    all             all             100.64.0.0/10           md5

# Block everything else for safety
host    all             all             0.0.0.0/0               reject
host    all             all             ::/0                    reject
EOF"

echo "==== Installing optimized postgresql.conf ===="
docker exec -i pg-mimicdb sh -c "cat > /var/lib/postgresql/18/main/postgresql.conf << 'EOF'
# ===================================================================
# PostgreSQL 18 Configuration - UGREEN NAS (8 GB DDR5)
# ===================================================================

# ------------------------------
# CONNECTIONS
# ------------------------------
listen_addresses = '*'
max_connections = 200

# ------------------------------
# MEMORY SETTINGS (8 GB optimized)
# ------------------------------
shared_buffers = 2GB
effective_cache_size = 5GB
work_mem = 32MB
maintenance_work_mem = 512MB

# ------------------------------
# CHECKPOINTS / WAL
# (optimized for HDD / NAS)
# ------------------------------
wal_level = replica
max_wal_size = 2GB
min_wal_size = 512MB
checkpoint_timeout = 15min
checkpoint_completion_target = 0.9
wal_compression = on

# ------------------------------
# QUERY PLANNING / PERFORMANCE
# ------------------------------
random_page_cost = 4.0
seq_page_cost = 1.0
effective_io_concurrency = 50

# ------------------------------
# LOGGING
# ------------------------------
logging_collector = on
log_line_prefix = '%m [%p] '
log_min_duration_statement = 500ms

# ------------------------------
# AUTOVACUUM TUNING
# ------------------------------
autovacuum = on
autovacuum_vacuum_cost_limit = 2000
autovacuum_analyze_scale_factor = 0.05
autovacuum_vacuum_scale_factor = 0.05
autovacuum_naptime = 30s

# ------------------------------
# SSL
# ------------------------------
ssl = off   # Tailscale provides encryption

# ------------------------------
# CLIENT CONNECTION BEHAVIOR
# ------------------------------
tcp_keepalives_idle = 60
tcp_keepalives_interval = 30
tcp_keepalives_count = 10
EOF"

echo "==== Fixing permissions (required by PostgreSQL) ===="
docker exec -i pg-mimicdb sh -c "chown 999:999 /var/lib/postgresql/18/main/pg_hba.conf"
docker exec -i pg-mimicdb sh -c "chown 999:999 /var/lib/postgresql/18/main/postgresql.conf"
docker exec -i pg-mimicdb sh -c "chmod 600 /var/lib/postgresql/18/main/pg_hba.conf"
docker exec -i pg-mimicdb sh -c "chmod 600 /var/lib/postgresql/18/main/postgresql.conf"

echo "==== Restarting PostgreSQL container ===="
docker restart pg-mimicdb

echo "==== DONE! The updated PostgreSQL configuration is now active. ===="
