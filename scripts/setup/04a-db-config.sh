#!/bin/bash
# =============================================================================
# 04a-db-config.sh - Apply PostgreSQL Config (Single Source of Truth)
# =============================================================================
# Generates a MINIMAL postgresql.conf with only paths/includes
# ALL tuning goes into conf.d/99-tuning.conf
#
# Data: /data/postgresql (RAID md0)
# WAL:  /wal/pg_wal (RAID md1)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/primary.env"

echo "=== Applying PostgreSQL Configuration ==="

# Source config
if [[ -f "$CONFIG_FILE" ]]; then
    echo "Loading config from: $CONFIG_FILE"
    source "$CONFIG_FILE"
else
    echo "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Paths (RAID)
PG_VERSION=${PG_VERSION:-16}
PG_DATA_DIR=${PG_DATA_DIR:-/data/postgresql}
PG_WAL_DIR=${PG_WAL_DIR:-/wal/pg_wal}
PG_CONF_D="${PG_DATA_DIR}/conf.d"

echo "Data directory: $PG_DATA_DIR (RAID)"
echo "WAL directory:  $PG_WAL_DIR (RAID)"

# Create conf.d
mkdir -p "$PG_CONF_D"

# =============================================================================
# STEP 1: Create minimal postgresql.conf (paths + include only)
# =============================================================================
echo "Creating minimal postgresql.conf..."

cat > "${PG_DATA_DIR}/postgresql.conf" << EOF
# =============================================================================
# PostgreSQL Configuration - MINIMAL (paths only)
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
# =============================================================================
# ALL tuning settings are in conf.d/99-tuning.conf
# DO NOT add settings here - they will be overwritten
# =============================================================================

# --- PATHS ---
data_directory = '${PG_DATA_DIR}'
hba_file = '${PG_DATA_DIR}/pg_hba.conf'
ident_file = '${PG_DATA_DIR}/pg_ident.conf'

# --- CONNECTIONS ---
listen_addresses = '*'
port = 5432

# --- INCLUDE TUNING ---
include_dir = 'conf.d'
EOF

# =============================================================================
# STEP 2: Create complete tuning config in conf.d
# =============================================================================
TUNING_CONF="$PG_CONF_D/99-tuning.conf"
echo "Writing tuning config to: $TUNING_CONF"

cat > "$TUNING_CONF" << EOF
# =============================================================================
# PostgreSQL Tuning - Single Source of Truth
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
# Source: primary.env
# =============================================================================

# === MEMORY ===
shared_buffers = '${PG_SHARED_BUFFERS:-8GB}'
effective_cache_size = '${PG_EFFECTIVE_CACHE_SIZE:-22GB}'
work_mem = '${PG_WORK_MEM:-128MB}'
maintenance_work_mem = '${PG_MAINTENANCE_WORK_MEM:-1638MB}'
huge_pages = '${PG_HUGE_PAGES:-try}'

# === CONNECTIONS ===
max_connections = ${PG_MAX_CONNECTIONS:-300}

# === WAL ===
wal_level = '${PG_WAL_LEVEL:-replica}'
wal_compression = '${PG_WAL_COMPRESSION:-lz4}'
wal_sync_method = '${PG_WAL_SYNC_METHOD:-fdatasync}'
wal_buffers = '${PG_WAL_BUFFERS:-64MB}'
wal_writer_delay = '${PG_WAL_WRITER_DELAY:-10ms}'
synchronous_commit = '${PG_SYNCHRONOUS_COMMIT:-on}'
max_wal_size = '${PG_MAX_WAL_SIZE:-32GB}'
min_wal_size = '${PG_MIN_WAL_SIZE:-2GB}'

# === GROUP COMMIT ===
commit_delay = ${PG_COMMIT_DELAY:-10}
commit_siblings = ${PG_COMMIT_SIBLINGS:-5}

# === CHECKPOINT ===
checkpoint_timeout = '${PG_CHECKPOINT_TIMEOUT:-15min}'
checkpoint_completion_target = ${PG_CHECKPOINT_COMPLETION_TARGET:-0.9}

# === BACKGROUND WRITER ===
bgwriter_delay = '${PG_BGWRITER_DELAY:-10ms}'
bgwriter_lru_maxpages = ${PG_BGWRITER_LRU_MAXPAGES:-400}
bgwriter_lru_multiplier = ${PG_BGWRITER_LRU_MULTIPLIER:-4}

# === PARALLEL ===
max_worker_processes = ${PG_MAX_WORKER_PROCESSES:-4}
max_parallel_workers = ${PG_MAX_PARALLEL_WORKERS:-4}
max_parallel_workers_per_gather = ${PG_MAX_PARALLEL_WORKERS_PER_GATHER:-2}
max_parallel_maintenance_workers = ${PG_MAX_PARALLEL_MAINTENANCE_WORKERS:-2}

# === I/O ===
effective_io_concurrency = ${PG_EFFECTIVE_IO_CONCURRENCY:-200}
maintenance_io_concurrency = ${PG_MAINTENANCE_IO_CONCURRENCY:-10}
random_page_cost = ${PG_RANDOM_PAGE_COST:-1.1}
seq_page_cost = ${PG_SEQ_PAGE_COST:-1.0}

# === AUTOVACUUM ===
autovacuum = ${PG_AUTOVACUUM:-on}
track_counts = ${PG_TRACK_COUNTS:-on}
autovacuum_vacuum_scale_factor = ${PG_AUTOVACUUM_VACUUM_SCALE_FACTOR:-0.05}
autovacuum_analyze_scale_factor = ${PG_AUTOVACUUM_ANALYZE_SCALE_FACTOR:-0.02}
autovacuum_vacuum_cost_limit = ${PG_AUTOVACUUM_VACUUM_COST_LIMIT:-2000}
autovacuum_vacuum_cost_delay = '${PG_AUTOVACUUM_VACUUM_COST_DELAY:-2ms}'

# === LOGGING ===
logging_collector = ${PG_LOGGING_COLLECTOR:-on}
log_directory = '${PG_LOG_DIRECTORY:-log}'
log_filename = '${PG_LOG_FILENAME:-postgresql-%Y-%m-%d_%H%M%S.log}'
log_min_duration_statement = ${PG_LOG_MIN_DURATION_STATEMENT:-1000}
log_checkpoints = ${PG_LOG_CHECKPOINTS:-on}
log_lock_waits = ${PG_LOG_LOCK_WAITS:-on}
log_temp_files = ${PG_LOG_TEMP_FILES:-0}
log_autovacuum_min_duration = ${PG_LOG_AUTOVACUUM_MIN_DURATION:-0}

# === QUERY TUNING ===
jit = ${PG_JIT:-off}

# === STATS ===
track_io_timing = ${PG_TRACK_IO_TIMING:-on}
track_wal_io_timing = ${PG_TRACK_WAL_IO_TIMING:-on}
EOF

# Set ownership
chown -R postgres:postgres "$PG_CONF_D"
chown postgres:postgres "${PG_DATA_DIR}/postgresql.conf"

# Remove any old conf.d files
rm -f "$PG_CONF_D/00-calculated.conf" 2>/dev/null || true

echo ""
echo "=== PostgreSQL Configuration Complete ==="
echo "Main config: ${PG_DATA_DIR}/postgresql.conf (minimal - paths only)"
echo "Tuning:      ${TUNING_CONF} (all settings)"
echo ""
echo "Restart PostgreSQL to apply: sudo systemctl restart postgresql@16-main"
echo "Or: sudo -u postgres pg_ctl restart -D ${PG_DATA_DIR}"
