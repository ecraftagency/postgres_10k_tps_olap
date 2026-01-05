#!/bin/bash
# =============================================================================
# COMPREHENSIVE CONFIGURATION VERIFICATION SCRIPT
# =============================================================================
# Verifies all ~110 settings from config.env against actual system state
# Categories: OS, RAID, XFS, Block Devices, PostgreSQL
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Accept config file as argument
if [ -n "$1" ]; then
    CONFIG_FILE="$1"
else
    # Default: look for config.env in parent scripts/ directory
    CONFIG_FILE="${SCRIPT_DIR}/../../scripts/config.env"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    echo "Usage: $0 [config_file]"
    exit 1
fi

source "$CONFIG_FILE"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

FAILED=0
TOTAL=0
PASSED=0

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}$1${NC}"
}

verify() {
    local name="$1"
    local expected="$2"
    local actual="$3"

    TOTAL=$((TOTAL + 1))

    # Normalize for comparison
    exp_norm=$(echo "$expected" | tr '[:upper:]' '[:lower:]' | sed 's/\.0$//')
    act_norm=$(echo "$actual" | tr '[:upper:]' '[:lower:]' | sed 's/\.0$//')

    if [[ "$exp_norm" == "$act_norm" ]]; then
        status="${GREEN}OK${NC}"
        PASSED=$((PASSED + 1))
    else
        status="${RED}MISMATCH${NC}"
        FAILED=$((FAILED + 1))
    fi

    printf "  %-40s %-20s %-20s " "$name" "$expected" "$actual"
    echo -e "$status"
}

get_sysctl() {
    sysctl -n "$1" 2>/dev/null || echo "N/A"
}

get_block_param() {
    local dev="$1"
    local param="$2"
    cat "/sys/block/${dev}/queue/${param}" 2>/dev/null || echo "N/A"
}

# =============================================================================
# VERIFICATION HEADER
# =============================================================================

echo "============================================================================="
echo "COMPREHENSIVE CONFIGURATION VERIFICATION"
echo "============================================================================="
echo "Config: ${CONFIG_FILE}"
echo "Date: $(date)"
echo ""
printf "%-42s %-20s %-20s %s\n" "Setting" "Expected" "Actual" "Status"
printf "%-42s %-20s %-20s %s\n" "------------------------------------------" "--------------------" "--------------------" "------"

# =============================================================================
# 1. OS TUNING - MEMORY
# =============================================================================

print_header "OS TUNING - MEMORY"

verify "vm.swappiness" "$VM_SWAPPINESS" "$(get_sysctl vm.swappiness)"
verify "vm.nr_hugepages" "$VM_NR_HUGEPAGES" "$(get_sysctl vm.nr_hugepages)"
verify "vm.dirty_background_ratio" "$VM_DIRTY_BACKGROUND_RATIO" "$(get_sysctl vm.dirty_background_ratio)"
verify "vm.dirty_ratio" "$VM_DIRTY_RATIO" "$(get_sysctl vm.dirty_ratio)"
verify "vm.dirty_expire_centisecs" "$VM_DIRTY_EXPIRE_CENTISECS" "$(get_sysctl vm.dirty_expire_centisecs)"
verify "vm.dirty_writeback_centisecs" "$VM_DIRTY_WRITEBACK_CENTISECS" "$(get_sysctl vm.dirty_writeback_centisecs)"
verify "vm.overcommit_memory" "$VM_OVERCOMMIT_MEMORY" "$(get_sysctl vm.overcommit_memory)"
verify "vm.overcommit_ratio" "$VM_OVERCOMMIT_RATIO" "$(get_sysctl vm.overcommit_ratio)"
verify "vm.min_free_kbytes" "$VM_MIN_FREE_KBYTES" "$(get_sysctl vm.min_free_kbytes)"
verify "vm.zone_reclaim_mode" "$VM_ZONE_RECLAIM_MODE" "$(get_sysctl vm.zone_reclaim_mode)"

# =============================================================================
# 2. OS TUNING - FILE DESCRIPTORS
# =============================================================================

print_header "OS TUNING - FILE DESCRIPTORS"

verify "fs.file-max" "$FS_FILE_MAX" "$(get_sysctl fs.file-max)"
verify "fs.aio-max-nr" "$FS_AIO_MAX_NR" "$(get_sysctl fs.aio-max-nr)"

# Check ulimits for postgres user
PG_NOFILE=$(sudo -u postgres bash -c 'ulimit -n' 2>/dev/null || echo "N/A")
PG_NPROC=$(sudo -u postgres bash -c 'ulimit -u' 2>/dev/null || echo "N/A")
verify "ulimit -n (postgres)" "$ULIMIT_NOFILE" "$PG_NOFILE"
verify "ulimit -u (postgres)" "$ULIMIT_NPROC" "$PG_NPROC"

# =============================================================================
# 3. OS TUNING - NETWORK/TCP
# =============================================================================

print_header "OS TUNING - NETWORK/TCP"

verify "net.core.somaxconn" "$NET_CORE_SOMAXCONN" "$(get_sysctl net.core.somaxconn)"
verify "net.core.netdev_max_backlog" "$NET_CORE_NETDEV_MAX_BACKLOG" "$(get_sysctl net.core.netdev_max_backlog)"
verify "net.core.rmem_default" "$NET_CORE_RMEM_DEFAULT" "$(get_sysctl net.core.rmem_default)"
verify "net.core.rmem_max" "$NET_CORE_RMEM_MAX" "$(get_sysctl net.core.rmem_max)"
verify "net.core.wmem_default" "$NET_CORE_WMEM_DEFAULT" "$(get_sysctl net.core.wmem_default)"
verify "net.core.wmem_max" "$NET_CORE_WMEM_MAX" "$(get_sysctl net.core.wmem_max)"
verify "net.ipv4.tcp_max_syn_backlog" "$NET_IPV4_TCP_MAX_SYN_BACKLOG" "$(get_sysctl net.ipv4.tcp_max_syn_backlog)"
verify "net.ipv4.tcp_tw_reuse" "$NET_IPV4_TCP_TW_REUSE" "$(get_sysctl net.ipv4.tcp_tw_reuse)"
verify "net.ipv4.tcp_fin_timeout" "$NET_IPV4_TCP_FIN_TIMEOUT" "$(get_sysctl net.ipv4.tcp_fin_timeout)"

# TCP buffer arrays need special handling
TCP_RMEM_ACTUAL=$(get_sysctl net.ipv4.tcp_rmem | tr '\t' ' ')
TCP_WMEM_ACTUAL=$(get_sysctl net.ipv4.tcp_wmem | tr '\t' ' ')
verify "net.ipv4.tcp_rmem" "$NET_IPV4_TCP_RMEM" "$TCP_RMEM_ACTUAL"
verify "net.ipv4.tcp_wmem" "$NET_IPV4_TCP_WMEM" "$TCP_WMEM_ACTUAL"

# =============================================================================
# 4. OS TUNING - SCHEDULER
# =============================================================================

print_header "OS TUNING - SCHEDULER"

verify "kernel.sched_autogroup_enabled" "$KERNEL_SCHED_AUTOGROUP_ENABLED" "$(get_sysctl kernel.sched_autogroup_enabled)"
verify "kernel.numa_balancing" "$KERNEL_NUMA_BALANCING" "$(get_sysctl kernel.numa_balancing)"

SEM_ACTUAL=$(get_sysctl kernel.sem | tr '\t' ' ')
verify "kernel.sem" "$KERNEL_SEM" "$SEM_ACTUAL"

# =============================================================================
# 5. RAID CONFIG - DATA VOLUME
# =============================================================================

print_header "RAID CONFIG - DATA VOLUME"

if [ -b "$DATA_RAID_DEVICE" ]; then
    # Check RAID level
    RAID_LEVEL=$(sudo mdadm --detail "$DATA_RAID_DEVICE" 2>/dev/null | grep "Raid Level" | awk '{print $NF}' | sed 's/raid//')
    verify "data_raid_level" "$DATA_RAID_LEVEL" "$RAID_LEVEL"

    # Check chunk size
    CHUNK=$(sudo mdadm --detail "$DATA_RAID_DEVICE" 2>/dev/null | grep "Chunk Size" | awk '{print $NF}')
    verify "data_raid_chunk" "$DATA_RAID_CHUNK" "$CHUNK"

    # Check number of devices
    RAID_DEVS=$(sudo mdadm --detail "$DATA_RAID_DEVICE" 2>/dev/null | grep "Raid Devices" | awk '{print $NF}')
    verify "data_disk_count" "$DATA_DISK_COUNT" "$RAID_DEVS"

    # Mount point
    DATA_MOUNT_ACTUAL=$(mount | grep "$DATA_RAID_DEVICE" | awk '{print $3}')
    verify "data_mount" "$DATA_MOUNT" "$DATA_MOUNT_ACTUAL"
else
    echo "  [SKIP] DATA RAID device $DATA_RAID_DEVICE not found"
fi

# =============================================================================
# 6. RAID CONFIG - WAL VOLUME
# =============================================================================

print_header "RAID CONFIG - WAL VOLUME"

if [ -b "$WAL_RAID_DEVICE" ]; then
    RAID_LEVEL=$(sudo mdadm --detail "$WAL_RAID_DEVICE" 2>/dev/null | grep "Raid Level" | awk '{print $NF}' | sed 's/raid//')
    verify "wal_raid_level" "$WAL_RAID_LEVEL" "$RAID_LEVEL"

    CHUNK=$(sudo mdadm --detail "$WAL_RAID_DEVICE" 2>/dev/null | grep "Chunk Size" | awk '{print $NF}')
    verify "wal_raid_chunk" "$WAL_RAID_CHUNK" "$CHUNK"

    RAID_DEVS=$(sudo mdadm --detail "$WAL_RAID_DEVICE" 2>/dev/null | grep "Raid Devices" | awk '{print $NF}')
    verify "wal_disk_count" "$WAL_DISK_COUNT" "$RAID_DEVS"

    WAL_MOUNT_ACTUAL=$(mount | grep "$WAL_RAID_DEVICE" | awk '{print $3}')
    verify "wal_mount" "$WAL_MOUNT" "$WAL_MOUNT_ACTUAL"
else
    echo "  [SKIP] WAL RAID device $WAL_RAID_DEVICE not found"
fi

# =============================================================================
# 7. MDADM TUNING
# =============================================================================

print_header "MDADM TUNING"

if [ -f /sys/block/md0/md/stripe_cache_size ]; then
    STRIPE_CACHE=$(cat /sys/block/md0/md/stripe_cache_size 2>/dev/null)
    verify "md_stripe_cache_size" "$MD_STRIPE_CACHE_SIZE" "$STRIPE_CACHE"
else
    echo "  [SKIP] MDADM stripe cache not available"
fi

# =============================================================================
# 8. XFS OPTIONS - DATA
# =============================================================================

print_header "XFS OPTIONS - DATA"

if mountpoint -q "$DATA_MOUNT" 2>/dev/null; then
    FS_TYPE_ACTUAL=$(df -T "$DATA_MOUNT" | tail -1 | awk '{print $2}')
    verify "data_fs_type" "$FS_TYPE" "$FS_TYPE_ACTUAL"

    # Check mount options
    MOUNT_OPTS_ACTUAL=$(mount | grep "$DATA_MOUNT " | sed 's/.*(\(.*\))/\1/')

    # Check key options
    [[ "$MOUNT_OPTS_ACTUAL" == *"noatime"* ]] && NOATIME="yes" || NOATIME="no"
    verify "data_noatime" "yes" "$NOATIME"

    [[ "$MOUNT_OPTS_ACTUAL" == *"nodiratime"* ]] && NODIRATIME="yes" || NODIRATIME="no"
    verify "data_nodiratime" "yes" "$NODIRATIME"

    [[ "$MOUNT_OPTS_ACTUAL" == *"inode64"* ]] && INODE64="yes" || INODE64="no"
    verify "data_inode64" "yes" "$INODE64"

    # XFS geometry from xfs_info
    if command -v xfs_info &>/dev/null; then
        XFS_INFO=$(xfs_info "$DATA_MOUNT" 2>/dev/null)
        DATA_AGCOUNT_ACTUAL=$(echo "$XFS_INFO" | grep -oP 'agcount=\K[0-9]+')
        verify "data_agcount" "$XFS_DATA_AGCOUNT" "$DATA_AGCOUNT_ACTUAL"
    fi
else
    echo "  [SKIP] DATA mount $DATA_MOUNT not found"
fi

# =============================================================================
# 9. XFS OPTIONS - WAL
# =============================================================================

print_header "XFS OPTIONS - WAL"

if mountpoint -q "$WAL_MOUNT" 2>/dev/null; then
    FS_TYPE_ACTUAL=$(df -T "$WAL_MOUNT" | tail -1 | awk '{print $2}')
    verify "wal_fs_type" "$FS_TYPE" "$FS_TYPE_ACTUAL"

    MOUNT_OPTS_ACTUAL=$(mount | grep "$WAL_MOUNT " | sed 's/.*(\(.*\))/\1/')

    [[ "$MOUNT_OPTS_ACTUAL" == *"noatime"* ]] && NOATIME="yes" || NOATIME="no"
    verify "wal_noatime" "yes" "$NOATIME"

    [[ "$MOUNT_OPTS_ACTUAL" == *"nodiratime"* ]] && NODIRATIME="yes" || NODIRATIME="no"
    verify "wal_nodiratime" "yes" "$NODIRATIME"

    [[ "$MOUNT_OPTS_ACTUAL" == *"inode64"* ]] && INODE64="yes" || INODE64="no"
    verify "wal_inode64" "yes" "$INODE64"

    # XFS geometry from xfs_info
    if command -v xfs_info &>/dev/null; then
        XFS_INFO=$(xfs_info "$WAL_MOUNT" 2>/dev/null)
        WAL_AGCOUNT_ACTUAL=$(echo "$XFS_INFO" | grep -oP 'agcount=\K[0-9]+')
        verify "wal_agcount" "$XFS_WAL_AGCOUNT" "$WAL_AGCOUNT_ACTUAL"
    fi
else
    echo "  [SKIP] WAL mount $WAL_MOUNT not found"
fi

# =============================================================================
# 10. BLOCK DEVICE TUNING - DATA (md0)
# =============================================================================
# Note: md devices (software RAID) don't have scheduler/nr_requests/rq_affinity
# These params are set on underlying NVMe devices, not on md array itself

print_header "BLOCK DEVICE TUNING - DATA (md0)"

if [ -d /sys/block/md0 ]; then
    verify "data_read_ahead_kb" "$DATA_READ_AHEAD_KB" "$(get_block_param md0 read_ahead_kb)"
    verify "data_rotational" "$DATA_ROTATIONAL" "$(get_block_param md0 rotational)"
    verify "data_add_random" "$DATA_ADD_RANDOM" "$(get_block_param md0 add_random)"
    verify "data_nomerges" "$DATA_NOMERGES" "$(get_block_param md0 nomerges)"
    verify "data_max_sectors_kb" "$DATA_MAX_SECTORS_KB" "$(get_block_param md0 max_sectors_kb)"
    echo "  [INFO] scheduler/nr_requests/rq_affinity N/A for md devices"
else
    echo "  [SKIP] md0 not found"
fi

# =============================================================================
# 11. BLOCK DEVICE TUNING - WAL (md1)
# =============================================================================

print_header "BLOCK DEVICE TUNING - WAL (md1)"

if [ -d /sys/block/md1 ]; then
    verify "wal_read_ahead_kb" "$WAL_READ_AHEAD_KB" "$(get_block_param md1 read_ahead_kb)"
    verify "wal_rotational" "$WAL_ROTATIONAL" "$(get_block_param md1 rotational)"
    verify "wal_add_random" "$WAL_ADD_RANDOM" "$(get_block_param md1 add_random)"
    verify "wal_nomerges" "$WAL_NOMERGES" "$(get_block_param md1 nomerges)"
    verify "wal_max_sectors_kb" "$WAL_MAX_SECTORS_KB" "$(get_block_param md1 max_sectors_kb)"
    echo "  [INFO] scheduler/nr_requests/rq_affinity N/A for md devices"
else
    echo "  [SKIP] md1 not found"
fi

# =============================================================================
# 12. POSTGRESQL - CONNECTIONS & MEMORY
# =============================================================================

print_header "POSTGRESQL - CONNECTIONS & MEMORY"

pg_show() {
    sudo -u postgres psql -t -c "SHOW $1;" 2>/dev/null | tr -d ' '
}

verify "max_connections" "$PG_MAX_CONNECTIONS" "$(pg_show max_connections)"
verify "shared_buffers" "$PG_SHARED_BUFFERS" "$(pg_show shared_buffers)"
verify "huge_pages" "$PG_HUGE_PAGES" "$(pg_show huge_pages)"
verify "work_mem" "$PG_WORK_MEM" "$(pg_show work_mem)"
verify "maintenance_work_mem" "$PG_MAINTENANCE_WORK_MEM" "$(pg_show maintenance_work_mem)"
verify "effective_cache_size" "$PG_EFFECTIVE_CACHE_SIZE" "$(pg_show effective_cache_size)"

# =============================================================================
# 13. POSTGRESQL - DISK I/O
# =============================================================================

print_header "POSTGRESQL - DISK I/O"

verify "random_page_cost" "$PG_RANDOM_PAGE_COST" "$(pg_show random_page_cost)"
verify "seq_page_cost" "$PG_SEQ_PAGE_COST" "$(pg_show seq_page_cost)"
verify "effective_io_concurrency" "$PG_EFFECTIVE_IO_CONCURRENCY" "$(pg_show effective_io_concurrency)"

# =============================================================================
# 14. POSTGRESQL - WAL
# =============================================================================

print_header "POSTGRESQL - WAL"

verify "wal_compression" "$PG_WAL_COMPRESSION" "$(pg_show wal_compression)"
verify "wal_buffers" "$PG_WAL_BUFFERS" "$(pg_show wal_buffers)"
verify "wal_writer_delay" "$PG_WAL_WRITER_DELAY" "$(pg_show wal_writer_delay)"
verify "wal_writer_flush_after" "$PG_WAL_WRITER_FLUSH_AFTER" "$(pg_show wal_writer_flush_after)"

# =============================================================================
# 15. POSTGRESQL - CHECKPOINT
# =============================================================================

print_header "POSTGRESQL - CHECKPOINT"

verify "max_wal_size" "$PG_MAX_WAL_SIZE" "$(pg_show max_wal_size)"
verify "min_wal_size" "$PG_MIN_WAL_SIZE" "$(pg_show min_wal_size)"
verify "checkpoint_timeout" "$PG_CHECKPOINT_TIMEOUT" "$(pg_show checkpoint_timeout)"
verify "checkpoint_completion_target" "$PG_CHECKPOINT_COMPLETION_TARGET" "$(pg_show checkpoint_completion_target)"

# =============================================================================
# 16. POSTGRESQL - SYNC & GROUP COMMIT
# =============================================================================

print_header "POSTGRESQL - SYNC & GROUP COMMIT"

verify "synchronous_commit" "$PG_SYNCHRONOUS_COMMIT" "$(pg_show synchronous_commit)"
verify "commit_delay" "$PG_COMMIT_DELAY" "$(pg_show commit_delay)"
verify "commit_siblings" "$PG_COMMIT_SIBLINGS" "$(pg_show commit_siblings)"

# =============================================================================
# 17. POSTGRESQL - BACKGROUND WRITER
# =============================================================================

print_header "POSTGRESQL - BACKGROUND WRITER"

verify "bgwriter_delay" "$PG_BGWRITER_DELAY" "$(pg_show bgwriter_delay)"
verify "bgwriter_lru_maxpages" "$PG_BGWRITER_LRU_MAXPAGES" "$(pg_show bgwriter_lru_maxpages)"
verify "bgwriter_lru_multiplier" "$PG_BGWRITER_LRU_MULTIPLIER" "$(pg_show bgwriter_lru_multiplier)"

# =============================================================================
# 18. POSTGRESQL - AUTOVACUUM
# =============================================================================

print_header "POSTGRESQL - AUTOVACUUM"

verify "autovacuum" "$PG_AUTOVACUUM" "$(pg_show autovacuum)"
verify "autovacuum_max_workers" "$PG_AUTOVACUUM_MAX_WORKERS" "$(pg_show autovacuum_max_workers)"
verify "autovacuum_naptime" "$PG_AUTOVACUUM_NAPTIME" "$(pg_show autovacuum_naptime)"
verify "autovacuum_vacuum_scale_factor" "$PG_AUTOVACUUM_VACUUM_SCALE_FACTOR" "$(pg_show autovacuum_vacuum_scale_factor)"
verify "autovacuum_analyze_scale_factor" "$PG_AUTOVACUUM_ANALYZE_SCALE_FACTOR" "$(pg_show autovacuum_analyze_scale_factor)"
verify "autovacuum_vacuum_cost_limit" "$PG_AUTOVACUUM_VACUUM_COST_LIMIT" "$(pg_show autovacuum_vacuum_cost_limit)"

# =============================================================================
# 19. POSTGRESQL - PARALLEL QUERY
# =============================================================================

print_header "POSTGRESQL - PARALLEL QUERY"

verify "max_worker_processes" "$PG_MAX_WORKER_PROCESSES" "$(pg_show max_worker_processes)"
verify "max_parallel_workers_per_gather" "$PG_MAX_PARALLEL_WORKERS_PER_GATHER" "$(pg_show max_parallel_workers_per_gather)"
verify "max_parallel_workers" "$PG_MAX_PARALLEL_WORKERS" "$(pg_show max_parallel_workers)"

# =============================================================================
# 20. POSTGRESQL - LOGGING
# =============================================================================

print_header "POSTGRESQL - LOGGING"

# Handle special case: 1000 == 1s
LOG_MIN_ACTUAL=$(pg_show log_min_duration_statement)
if [[ "$LOG_MIN_ACTUAL" == "1s" ]]; then
    LOG_MIN_ACTUAL="1000"
fi
verify "log_min_duration_statement" "$PG_LOG_MIN_DURATION_STATEMENT" "$LOG_MIN_ACTUAL"

verify "log_temp_files" "$PG_LOG_TEMP_FILES" "$(pg_show log_temp_files)"
verify "log_checkpoints" "$PG_LOG_CHECKPOINTS" "$(pg_show log_checkpoints)"
verify "log_lock_waits" "$PG_LOG_LOCK_WAITS" "$(pg_show log_lock_waits)"

# =============================================================================
# 21. POSTGRESQL - PATHS & VERSION
# =============================================================================

print_header "POSTGRESQL - PATHS & VERSION"

# Version check
PG_VER_ACTUAL=$(pg_show server_version_num | cut -c1-2)
verify "pg_version" "$PG_VERSION" "$PG_VER_ACTUAL"

verify "data_directory" "$PG_DATA_DIR" "$(pg_show data_directory)"
verify "port" "$PG_PORT" "$(pg_show port)"
verify "listen_addresses" "$PG_LISTEN_ADDRESSES" "$(pg_show listen_addresses)"

# WAL directory - check symlink target
WAL_DIR_ACTUAL=$(sudo readlink -f "$PG_DATA_DIR/pg_wal" 2>/dev/null || echo "$PG_DATA_DIR/pg_wal")
verify "wal_directory" "$PG_WAL_DIR" "$WAL_DIR_ACTUAL"

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "============================================================================="
echo "VERIFICATION SUMMARY"
echo "============================================================================="
echo -e "Total Settings:  ${TOTAL}"
echo -e "Passed:          ${GREEN}${PASSED}${NC}"
echo -e "Failed:          ${RED}${FAILED}${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}[SUCCESS] All ${TOTAL} configurations verified!${NC}"
    exit 0
else
    echo -e "${RED}[ERROR] ${FAILED} configurations need review${NC}"
    exit 1
fi
