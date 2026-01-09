#!/bin/bash
# =============================================================================
# 07-sysbench-init.sh - Initialize Sysbench TPC-C Database
# =============================================================================
# Creates ~20GB TPC-C dataset for sysbench benchmarking
# Database: sysbench
# Warehouses: 200 (~100MB per warehouse = ~20GB total)
# =============================================================================

set -e

# Configuration
DB_HOST="${1:-localhost}"
DB_PORT="${2:-5432}"
DB_USER="postgres"
DB_PASS="postgres"
DB_NAME="sysbench"
WAREHOUSES="${WAREHOUSES:-200}"  # ~100MB per warehouse (200=~20GB, 20=~2GB)
THREADS=4

echo "=== Sysbench TPC-C Initialization ==="
echo "Host: $DB_HOST:$DB_PORT"
echo "Database: $DB_NAME"
echo "Warehouses: $WAREHOUSES (~20GB)"
echo "Threads: $THREADS"
echo ""

# Create database if not exists (owned by postgres)
echo "--- Creating database $DB_NAME (owner: postgres) ---"
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -tc \
    "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || \
    PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "CREATE DATABASE $DB_NAME OWNER postgres"

# Ensure ownership is postgres
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "ALTER DATABASE $DB_NAME OWNER TO postgres"

# Run sysbench TPC-C prepare
echo ""
echo "--- Running sysbench TPC-C prepare (this will take a while) ---"
echo "Estimated time: 10-30 minutes depending on storage speed"
echo ""

START_TIME=$(date +%s)

sysbench /usr/share/sysbench/tpcc.lua \
    --db-driver=pgsql \
    --pgsql-host=$DB_HOST \
    --pgsql-port=$DB_PORT \
    --pgsql-user=$DB_USER \
    --pgsql-password=$DB_PASS \
    --pgsql-db=$DB_NAME \
    --threads=$THREADS \
    --tables=1 \
    --scale=$WAREHOUSES \
    --trx_level=RC \
    prepare

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "=== TPC-C Data Initialization Complete ==="
echo "Duration: ${DURATION}s"
echo ""

# Show database size
echo "--- Database Size ---"
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
    "SELECT pg_size_pretty(pg_database_size('$DB_NAME')) as db_size;"

# Show table sizes
echo ""
echo "--- Table Sizes ---"
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
    "SELECT relname as table_name,
            pg_size_pretty(pg_total_relation_size(relid)) as total_size,
            pg_size_pretty(pg_relation_size(relid)) as table_size,
            pg_size_pretty(pg_indexes_size(relid)) as index_size
     FROM pg_catalog.pg_statio_user_tables
     ORDER BY pg_total_relation_size(relid) DESC;"

# Analyze tables for query planner
echo ""
echo "--- Running ANALYZE ---"
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "ANALYZE;"

echo ""
echo "=== Done! Database '$DB_NAME' ready for sysbench TPC-C benchmarks ==="
