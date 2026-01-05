#!/bin/bash
# =============================================================================
# Sysbench OLTP Read-Only Benchmark
# =============================================================================
# Usage: ./bench.sh [threads] [duration]
#
# Default: 32 threads, 60 seconds
# =============================================================================

set -e

THREADS=${1:-32}
DURATION=${2:-60}
TABLES=10
TABLE_SIZE=1000000  # 1M rows per table = ~10M total

# PostgreSQL connection (TCP for sysbench)
PG_HOST="127.0.0.1"
PG_PORT=5432
PG_USER="postgres"
PG_PASS="postgres"
PG_DB="sysbench"

echo "=== Sysbench OLTP Read-Only Benchmark ==="
echo "Threads: $THREADS"
echo "Duration: ${DURATION}s"
echo "Tables: $TABLES x $TABLE_SIZE rows"
echo

# Common sysbench options
SYSBENCH_OPTS="
  --db-driver=pgsql
  --pgsql-host=$PG_HOST
  --pgsql-port=$PG_PORT
  --pgsql-user=$PG_USER
  --pgsql-password=$PG_PASS
  --pgsql-db=$PG_DB
  --tables=$TABLES
  --table-size=$TABLE_SIZE
  --threads=$THREADS
  --time=$DURATION
  --report-interval=10
"

# Check if database exists
echo "[1/3] Checking database..."
sudo -u postgres psql -c "SELECT 1 FROM pg_database WHERE datname = '$PG_DB'" | grep -q 1 || \
  sudo -u postgres createdb $PG_DB

# Check if tables exist
TABLE_COUNT=$(sudo -u postgres psql -d $PG_DB -t -c "SELECT COUNT(*) FROM pg_tables WHERE tablename LIKE 'sbtest%'" 2>/dev/null | tr -d ' ')

if [ "$TABLE_COUNT" -lt "$TABLES" ]; then
    echo "[2/3] Preparing tables..."
    sysbench oltp_read_only $SYSBENCH_OPTS prepare
else
    echo "[2/3] Tables already exist ($TABLE_COUNT tables)"
fi

echo "[3/3] Running benchmark..."
echo
sysbench oltp_read_only $SYSBENCH_OPTS run

echo
echo "=== Benchmark Complete ==="
