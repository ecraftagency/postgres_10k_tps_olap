#!/bin/bash
# =============================================================================
# 05-pgbench-init.sh - Initialize TPC-B Data
# =============================================================================
# Initializes pgbench TPC-B database with specified scale factor.
# Scale 1250 = ~20GB data (fits in shared_buffers for 8GB)
#
# Usage: sudo ./05-pgbench-init.sh [scale] [database]
# =============================================================================
set -euo pipefail

SCALE=${1:-1250}
DATABASE=${2:-bench}
PG_USER=${PG_USER:-postgres}

echo "=== pgbench TPC-B Initialization ==="
echo "Scale: ${SCALE} (~$((SCALE * 16))MB data)"
echo "Database: ${DATABASE}"

# Idempotent check: skip if data already exists with sufficient rows
EXPECTED_ROWS=$((SCALE * 100000))
EXISTING_ROWS=$(sudo -u postgres psql -d ${DATABASE} -tAc "SELECT count(*) FROM pgbench_accounts" 2>/dev/null || echo 0)

if [ "$EXISTING_ROWS" -ge "$EXPECTED_ROWS" ]; then
    echo "✓ Database already initialized with sufficient data (${EXISTING_ROWS} rows >= ${EXPECTED_ROWS} expected)."
    echo "  Skipping init. Use --force to reinitialize."
    exit 0
fi

echo "Current rows: ${EXISTING_ROWS}, Expected: ${EXPECTED_ROWS}. Initializing..."

# Drop and recreate database
echo "[1/3] Recreating database..."
sudo -u postgres psql -c "DROP DATABASE IF EXISTS ${DATABASE};" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE ${DATABASE} OWNER ${PG_USER};"

# Initialize pgbench
echo "[2/3] Initializing pgbench (this may take several minutes)..."
time sudo -u postgres pgbench -i -s ${SCALE} ${DATABASE}

# Verify
echo "[3/3] Verification..."
sudo -u postgres psql -d ${DATABASE} -c "\dt+ pgbench_*"

echo ""
echo "Database size:"
sudo -u postgres psql -c "SELECT pg_database.datname, pg_size_pretty(pg_database_size(pg_database.datname)) FROM pg_database WHERE datname = '${DATABASE}';"

echo ""
echo "=== TPC-B Init Complete ==="
echo "Scale: ${SCALE}"
echo "Ready for: sudo python3 ~/scripts/bench.py 11"
