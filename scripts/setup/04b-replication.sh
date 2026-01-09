#!/bin/bash
# =============================================================================
# 04b-replication.sh - PostgreSQL Streaming Replication Setup
# =============================================================================
# Sets up streaming replication from primary to standby nodes.
#
# Usage:
#   On PRIMARY: sudo ./04b-replication.sh primary
#   On STANDBY: sudo ./04b-replication.sh standby <role>
#               where role = sync-replica or async-replica
#
# Prerequisites:
#   - Primary must be running with 04-postgres.sh completed
#   - RAID and OS tuning must be done on standby
#   - Network connectivity between nodes
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"

MODE="${1:-}"
ROLE="${2:-}"

if [[ -z "$MODE" ]]; then
    echo "Usage: $0 <primary|standby> [role]"
    echo "  primary - Setup primary for replication (create replicator user)"
    echo "  standby <role> - Setup standby via pg_basebackup"
    echo "    role: sync-replica or async-replica"
    exit 1
fi

# =============================================================================
# PRIMARY SETUP
# =============================================================================
setup_primary() {
    echo "=== Setting up PRIMARY for replication ==="

    # Load primary config
    source "$CONFIG_DIR/db/primary.env"

    # Create replication user if not exists
    echo "[1/3] Creating replication user..."
    sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='replicator'" | grep -q 1 || \
        sudo -u postgres psql -c "CREATE USER replicator REPLICATION LOGIN PASSWORD 'replicator';"

    # Create replication slots for each replica
    echo "[2/3] Creating replication slots..."
    for slot in sync_replica async_replica; do
        sudo -u postgres psql -tc "SELECT 1 FROM pg_replication_slots WHERE slot_name='$slot'" | grep -q 1 || \
            sudo -u postgres psql -c "SELECT pg_create_physical_replication_slot('$slot');"
    done

    # Verify pg_hba.conf allows replication
    echo "[3/3] Verifying pg_hba.conf..."
    if ! grep -q "host.*replication.*10.0.0.0/16" "${PG_DATA_DIR}/pg_hba.conf"; then
        echo "WARNING: pg_hba.conf may not allow replication from VPC"
        echo "Ensure this line exists: host replication all 10.0.0.0/16 scram-sha-256"
    fi

    echo ""
    echo "=== Primary replication setup complete ==="
    echo "Replication slots:"
    sudo -u postgres psql -c "SELECT slot_name, active FROM pg_replication_slots;"
}

# =============================================================================
# STANDBY SETUP
# =============================================================================
setup_standby() {
    if [[ -z "$ROLE" ]]; then
        echo "ERROR: Role required for standby setup"
        echo "Usage: $0 standby <sync-replica|async-replica>"
        exit 1
    fi

    echo "=== Setting up STANDBY: $ROLE ==="

    # Load standby config
    CONFIG_FILE="$CONFIG_DIR/db/${ROLE}.env"
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "ERROR: Config file not found: $CONFIG_FILE"
        exit 1
    fi
    source "$CONFIG_FILE"

    PG_VERSION=${PG_VERSION:-16}
    PG_DATA_DIR=${PG_DATA_DIR:-/data/postgresql}
    PG_WAL_DIR=${PG_WAL_DIR:-/wal/pg_wal}
    PRIMARY_HOST=${PG_PRIMARY_HOST:-10.0.1.10}
    PRIMARY_PORT=${PG_PRIMARY_PORT:-5432}
    REPL_USER=${PG_REPLICATION_USER:-replicator}
    REPL_PASS=${PG_REPLICATION_PASSWORD:-replicator}
    CLUSTER_NAME=${PG_CLUSTER_NAME:-$ROLE}

    # Determine slot name (convert dashes to underscores)
    SLOT_NAME=$(echo "$ROLE" | tr '-' '_')

    # Stop PostgreSQL if running
    echo "[1/6] Stopping PostgreSQL if running..."
    systemctl stop postgresql-bench 2>/dev/null || true

    # Clear existing data directory
    echo "[2/6] Clearing existing data directory..."
    rm -rf "${PG_DATA_DIR:?}"/*
    rm -rf "${PG_WAL_DIR:?}"/* 2>/dev/null || true

    # Ensure directories exist with correct permissions
    mkdir -p "$PG_DATA_DIR" "$PG_WAL_DIR"
    chown postgres:postgres "$PG_DATA_DIR" "$PG_WAL_DIR"
    chmod 700 "$PG_DATA_DIR" "$PG_WAL_DIR"

    # pg_basebackup from primary
    echo "[3/6] Running pg_basebackup from primary ($PRIMARY_HOST)..."
    PGPASSWORD="$REPL_PASS" sudo -u postgres /usr/lib/postgresql/${PG_VERSION}/bin/pg_basebackup \
        -h "$PRIMARY_HOST" \
        -p "$PRIMARY_PORT" \
        -U "$REPL_USER" \
        -D "$PG_DATA_DIR" \
        --waldir="$PG_WAL_DIR" \
        -Fp -Xs -P -R \
        --slot="$SLOT_NAME" \
        -c fast

    # Create standby.signal
    echo "[4/6] Creating standby.signal..."
    touch "${PG_DATA_DIR}/standby.signal"
    chown postgres:postgres "${PG_DATA_DIR}/standby.signal"

    # Configure postgresql.auto.conf for replication
    echo "[5/6] Configuring replication settings..."
    cat >> "${PG_DATA_DIR}/postgresql.auto.conf" << EOF

# Standby configuration - generated by 04b-replication.sh
primary_conninfo = 'host=$PRIMARY_HOST port=$PRIMARY_PORT user=$REPL_USER password=$REPL_PASS application_name=$CLUSTER_NAME'
primary_slot_name = '$SLOT_NAME'
hot_standby = on
hot_standby_feedback = on
EOF

    # Update postgresql.conf with role-specific settings
    # Append cluster_name for identification
    echo "cluster_name = '$CLUSTER_NAME'" >> "${PG_DATA_DIR}/postgresql.conf"

    # Set ownership
    chown -R postgres:postgres "$PG_DATA_DIR"
    chown -R postgres:postgres "$PG_WAL_DIR"

    # Start PostgreSQL
    echo "[6/6] Starting PostgreSQL standby..."
    systemctl start postgresql-bench

    # Wait and verify
    sleep 5

    echo ""
    echo "=== Standby setup complete ==="
    echo "Verifying replication status..."

    # Check if in recovery mode
    local IN_RECOVERY=$(sudo -u postgres psql -t -c "SELECT pg_is_in_recovery();" | tr -d ' ')
    if [[ "$IN_RECOVERY" == "t" ]]; then
        echo "Recovery mode: YES (standby)"
    else
        echo "ERROR: Not in recovery mode!"
        exit 1
    fi

    # Show WAL receiver status
    echo ""
    echo "WAL Receiver Status:"
    sudo -u postgres psql -c "SELECT status, sender_host, sender_port, slot_name FROM pg_stat_wal_receiver;"
}

# =============================================================================
# MAIN
# =============================================================================
case "$MODE" in
    primary)
        setup_primary
        ;;
    standby)
        setup_standby
        ;;
    *)
        echo "Unknown mode: $MODE"
        echo "Usage: $0 <primary|standby> [role]"
        exit 1
        ;;
esac
