#!/bin/bash
# =============================================================================
# bootstrap.sh - Complete Benchmark Workflow
# =============================================================================
# Workflow: 
#   provision → sync → verify → baseline → sync results → evaluate
#   → optimize → sync → benchmark → ... → ceiling → golden fact
#
# IMPORTANT: All config changes happen LOCALLY first, then rsync to remote.
# This ensures consistency and reproducibility.
# =============================================================================

set -e

# Cleanup trap for local interruption
cleanup_local() {
    log "Interrupted. Cleaning up..."
    # Attempt to kill remote benchmarks if running
    if [ -f "$INFRA_JSON" ]; then
        log "Stopping remote processes..."
        ssh_run db "sudo pkill -f 'bench.py|pgbench|fio|iostat|mpstat' 2>/dev/null || true"
        ssh_run proxy "sudo pkill -f 'bench.py|pgbench|fio|iostat|mpstat' 2>/dev/null || true"
    fi
    exit 1
}
trap cleanup_local SIGINT

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_JSON="$SCRIPT_DIR/infra.json"
TERRAFORM_DIR="$SCRIPT_DIR/terraform/topologies/proxy-primary"
LOCAL_RESULTS="$SCRIPT_DIR/results"
REMOTE_HOME="/home/ubuntu"

# SSH Config (use default key per CLAUDE.MD rule 7)
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[bootstrap]${NC} $1"; }
warn() { echo -e "${YELLOW}[bootstrap]${NC} $1"; }
error() { echo -e "${RED}[bootstrap]${NC} $1"; exit 1; }

# AWS Config
AWS_REGION="ap-southeast-1"
AWS_PROFILE="boxloop-admin"

# =============================================================================
# HELPERS
# =============================================================================

get_db_ip() {
    if [ ! -f "$INFRA_JSON" ]; then
        error "No infra.json found. Run: ./bootstrap.sh provision"
    fi
    jq -r '.db_node.value.public_ip' "$INFRA_JSON"
}

get_proxy_ip() {
    if [ ! -f "$INFRA_JSON" ]; then
        error "No infra.json found. Run: ./bootstrap.sh provision"
    fi
    jq -r '.proxy_node.value.public_ip' "$INFRA_JSON"
}

ssh_run() {
    local target=$1
    shift
    local ip=""
    if [ "$target" == "db" ]; then ip=$(get_db_ip); else ip=$(get_proxy_ip); fi
    ssh $SSH_OPTS "ubuntu@$ip" "$@"
}

rsync_to_remote() {
    local target=$1
    local ip=""
    if [ "$target" == "db" ]; then ip=$(get_db_ip); else ip=$(get_proxy_ip); fi
    
    log "Syncing scripts to $target ($ip)..."
    ssh $SSH_OPTS "ubuntu@$ip" "sudo chown -R ubuntu:ubuntu $REMOTE_HOME/scripts/results 2>/dev/null || true"
    rsync -avz --delete \
        -e "ssh $SSH_OPTS" \
        "$SCRIPT_DIR/scripts/" \
        "ubuntu@$ip:$REMOTE_HOME/scripts/"
}

rsync_from_remote() {
    local target=$1
    local ip=""
    if [ "$target" == "db" ]; then ip=$(get_db_ip); else ip=$(get_proxy_ip); fi
    
    log "Syncing results from $target ($ip) to local..."
    mkdir -p "$LOCAL_RESULTS"
    rsync -avz \
        -e "ssh $SSH_OPTS" \
        "ubuntu@$ip:$REMOTE_HOME/scripts/results/" \
        "$LOCAL_RESULTS/"
}

wait_for_ssh() {
    local ip=$1
    log "Waiting for SSH on $ip..."
    for i in {1..120}; do
        if ssh $SSH_OPTS "ubuntu@$ip" "echo ok" &>/dev/null; then
            log "SSH ready for $ip!"
            return 0
        fi
        echo -n "."
        sleep 5
    done
    error "SSH timeout for $ip"
}

wait_for_service() {
    local target=$1
    local service=$2
    local timeout=${3:-30}

    log "Waiting for $service on $target..."
    for i in $(seq 1 $timeout); do
        local status=$(ssh_run $target "sudo systemctl is-active $service 2>/dev/null || echo inactive")
        if [ "$status" == "active" ]; then
            log "$service is running on $target"
            return 0
        fi
        echo -n "."
        sleep 1
    done
    echo ""
    warn "$service did not start within ${timeout}s on $target"
    ssh_run $target "sudo systemctl status $service --no-pager" || true
    return 1
}

# =============================================================================
# COMMANDS
# =============================================================================

cmd_provision() {
    log "=== PROVISIONING ==="
    cd "$TERRAFORM_DIR"
    terraform apply -auto-approve
    terraform output -json > "$INFRA_JSON"
    cd "$SCRIPT_DIR"
    
    wait_for_ssh $(get_db_ip)
    wait_for_ssh $(get_proxy_ip)
    
    cmd_sync
    cmd_setup
}

cmd_sync() {
    log "=== SYNCING ==="
    rsync_to_remote db
    rsync_to_remote proxy
}

cmd_apply() {
    local target="${1:-all}"  # all, os, disk, tcp, postgres, pgcat

    cmd_sync

    case "$target" in
        os)
            log "=== APPLYING OS CONFIG (memory, kernel) ==="
            ssh_run db "sudo $REMOTE_HOME/scripts/setup/01-os-tuning.sh"
            log "OS config applied (reboot may be needed for some settings)"
            ;;
        disk)
            log "=== APPLYING DISK CONFIG ==="
            ssh_run db "sudo $REMOTE_HOME/scripts/setup/03-disk-tuning.sh"
            log "Disk config applied"
            ;;
        tcp)
            log "=== APPLYING TCP CONFIG ==="
            ssh_run db "sudo sysctl -p /etc/sysctl.d/99-postgres.conf 2>/dev/null || sudo $REMOTE_HOME/scripts/setup/01-os-tuning.sh"
            ssh_run proxy "sudo sysctl -p /etc/sysctl.d/99-postgres.conf 2>/dev/null || true"
            log "TCP config applied"
            ;;
        postgres|db)
            log "=== APPLYING POSTGRESQL CONFIG ==="
            ssh_run db "sudo $REMOTE_HOME/scripts/setup/04a-db-config.sh"
            log "Generated config:"
            ssh_run db "sudo grep -E '^(work_mem|autovacuum_vacuum_cost_limit|log_autovacuum)' /data/postgresql/conf.d/99-tuning.conf || true"
            log "Restarting PostgreSQL..."
            ssh_run db "sudo -u postgres /usr/lib/postgresql/16/bin/pg_ctl restart -D /data/postgresql -w -t 30"
            log "Verifying PostgreSQL is running on RAID..."
            ssh_run db "sudo -u postgres psql -c \"SELECT name, setting FROM pg_settings WHERE name IN ('data_directory', 'work_mem', 'autovacuum_vacuum_cost_limit');\""
            ;;
        pgcat|proxy)
            log "=== APPLYING PGCAT CONFIG ==="
            ssh_run proxy "sudo cp $REMOTE_HOME/scripts/config/pgcat.toml /etc/pgcat/pgcat.toml && sudo systemctl restart pgcat"
            wait_for_service proxy pgcat
            ;;
        all)
            log "=== APPLYING ALL CONFIGS ==="
            ssh_run db "sudo $REMOTE_HOME/scripts/setup/01-os-tuning.sh"
            ssh_run db "sudo $REMOTE_HOME/scripts/setup/03-disk-tuning.sh"
            ssh_run db "sudo $REMOTE_HOME/scripts/setup/04a-db-config.sh"
            ssh_run db "sudo -u postgres /usr/lib/postgresql/16/bin/pg_ctl restart -D /data/postgresql -w -t 30"
            ssh_run proxy "sudo cp $REMOTE_HOME/scripts/config/pgcat.toml /etc/pgcat/pgcat.toml && sudo systemctl restart pgcat"
            wait_for_service proxy pgcat
            ;;
        *)
            error "Unknown target: $target (use: all, os, disk, tcp, postgres, pgcat)"
            ;;
    esac
}

cmd_setup() {
    log "=== SETUP ==="
    local DB_VCPU=$(jq -r '.db_node.value.vcpu' "$INFRA_JSON")
    local DB_RAM=$(jq -r '.db_node.value.ram_gb' "$INFRA_JSON")
    
    log "Remote Setup: DB..."
    ssh_run db "sudo chmod +x $REMOTE_HOME/scripts/setup/*.sh"
    ssh_run db "sudo $REMOTE_HOME/scripts/setup/all.sh --vcpu $DB_VCPU --ram $DB_RAM"
    
    log "Remote Setup: Proxy..."
    ssh_run proxy "sudo chmod +x $REMOTE_HOME/scripts/setup/*.sh"
    ssh_run proxy "sudo $REMOTE_HOME/scripts/setup/all.sh"
}

cmd_verify() {
    log "=== CONFIGURATION VERIFICATION ==="

    local CONFIG_DIR="$SCRIPT_DIR/scripts/config"
    local MISMATCH_COUNT=0

    # Colors for status
    local MATCH="${GREEN}matched${NC}"
    local MISMATCH="${RED}MISMATCH${NC}"

    # Load local configs
    source "$CONFIG_DIR/os.env" 2>/dev/null || true
    source "$CONFIG_DIR/base.env" 2>/dev/null || true
    source "$CONFIG_DIR/primary.env" 2>/dev/null || true

    # Print header
    echo ""
    printf "%-45s | %-20s | %-20s | %s\n" "CONFIG" "LOCAL" "ACTUAL" "STATUS"
    printf '%100s\n' | tr ' ' '='

    # Helper function to check and print
    check_config() {
        local name="$1"
        local local_val="$2"
        local actual_val="$3"
        local status=""

        # Normalize values for comparison
        local norm_local=$(echo "$local_val" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
        local norm_actual=$(echo "$actual_val" | tr -d ' ' | tr '[:upper:]' '[:lower:]')

        if [ "$norm_local" == "$norm_actual" ]; then
            status="matched"
            printf "%-45s | %-20s | %-20s | ${GREEN}%s${NC}\n" "$name" "$local_val" "$actual_val" "$status"
        else
            status="MISMATCH"
            MISMATCH_COUNT=$((MISMATCH_COUNT + 1))
            printf "%-45s | %-20s | %-20s | ${RED}%s${NC}\n" "$name" "$local_val" "$actual_val" "$status"
        fi
    }

    print_category() {
        echo ""
        echo -e "${BLUE}### $1${NC}"
        printf '%100s\n' | tr ' ' '-'
    }

    # =========================================================================
    # OS - MEMORY
    # =========================================================================
    print_category "OS - Memory"

    local OS_ACTUAL=$(ssh_run db "cat /proc/sys/vm/swappiness /proc/sys/vm/dirty_ratio /proc/sys/vm/dirty_background_ratio /proc/sys/vm/dirty_expire_centisecs /proc/sys/vm/dirty_writeback_centisecs /proc/sys/vm/overcommit_memory /proc/sys/vm/overcommit_ratio /proc/sys/vm/min_free_kbytes /proc/sys/vm/zone_reclaim_mode /proc/sys/vm/nr_hugepages 2>/dev/null | tr '\n' ' '")
    read -r A_SWAP A_DIRTY A_DIRTY_BG A_EXPIRE A_WRITEBACK A_OVERCOMMIT A_OVERCOMMIT_R A_MINFREE A_ZONE A_HUGEPAGES <<< "$OS_ACTUAL"

    check_config "vm.swappiness" "$VM_SWAPPINESS" "$A_SWAP"
    check_config "vm.dirty_ratio" "$VM_DIRTY_RATIO" "$A_DIRTY"
    check_config "vm.dirty_background_ratio" "$VM_DIRTY_BACKGROUND_RATIO" "$A_DIRTY_BG"
    check_config "vm.dirty_expire_centisecs" "$VM_DIRTY_EXPIRE_CENTISECS" "$A_EXPIRE"
    check_config "vm.dirty_writeback_centisecs" "$VM_DIRTY_WRITEBACK_CENTISECS" "$A_WRITEBACK"
    check_config "vm.overcommit_memory" "$VM_OVERCOMMIT_MEMORY" "$A_OVERCOMMIT"
    check_config "vm.overcommit_ratio" "$VM_OVERCOMMIT_RATIO" "$A_OVERCOMMIT_R"
    check_config "vm.min_free_kbytes" "$VM_MIN_FREE_KBYTES" "$A_MINFREE"
    check_config "vm.zone_reclaim_mode" "$VM_ZONE_RECLAIM_MODE" "$A_ZONE"
    check_config "vm.nr_hugepages" "$VM_NR_HUGEPAGES" "$A_HUGEPAGES"

    # =========================================================================
    # OS - KERNEL
    # =========================================================================
    print_category "OS - Kernel"

    local KERNEL_ACTUAL=$(ssh_run db "cat /proc/sys/kernel/sched_autogroup_enabled /proc/sys/kernel/numa_balancing 2>/dev/null | tr '\n' ' '")
    read -r A_AUTOGROUP A_NUMA <<< "$KERNEL_ACTUAL"

    check_config "kernel.sched_autogroup_enabled" "$KERNEL_SCHED_AUTOGROUP_ENABLED" "$A_AUTOGROUP"
    check_config "kernel.numa_balancing" "$KERNEL_NUMA_BALANCING" "$A_NUMA"

    # =========================================================================
    # OS - TCP/NETWORK
    # =========================================================================
    print_category "OS - TCP/Network"

    local TCP_ACTUAL=$(ssh_run db "cat /proc/sys/net/core/somaxconn /proc/sys/net/core/netdev_max_backlog /proc/sys/net/ipv4/tcp_max_syn_backlog /proc/sys/net/ipv4/tcp_tw_reuse /proc/sys/net/ipv4/tcp_fin_timeout 2>/dev/null | tr '\n' ' '")
    read -r A_SOMAXCONN A_BACKLOG A_SYNBACKLOG A_TWREUSE A_FINTIMEOUT <<< "$TCP_ACTUAL"

    check_config "net.core.somaxconn" "$NET_CORE_SOMAXCONN" "$A_SOMAXCONN"
    check_config "net.core.netdev_max_backlog" "$NET_CORE_NETDEV_MAX_BACKLOG" "$A_BACKLOG"
    check_config "net.ipv4.tcp_max_syn_backlog" "$NET_IPV4_TCP_MAX_SYN_BACKLOG" "$A_SYNBACKLOG"
    check_config "net.ipv4.tcp_tw_reuse" "$NET_IPV4_TCP_TW_REUSE" "$A_TWREUSE"
    check_config "net.ipv4.tcp_fin_timeout" "$NET_IPV4_TCP_FIN_TIMEOUT" "$A_FINTIMEOUT"

    # TCP Keepalive
    local TCP_KA=$(ssh_run db "cat /proc/sys/net/ipv4/tcp_keepalive_time /proc/sys/net/ipv4/tcp_keepalive_intvl /proc/sys/net/ipv4/tcp_keepalive_probes 2>/dev/null | tr '\n' ' '")
    read -r A_KA_TIME A_KA_INTVL A_KA_PROBES <<< "$TCP_KA"

    check_config "net.ipv4.tcp_keepalive_time" "$NET_IPV4_TCP_KEEPALIVE_TIME" "$A_KA_TIME"
    check_config "net.ipv4.tcp_keepalive_intvl" "$NET_IPV4_TCP_KEEPALIVE_INTVL" "$A_KA_INTVL"
    check_config "net.ipv4.tcp_keepalive_probes" "$NET_IPV4_TCP_KEEPALIVE_PROBES" "$A_KA_PROBES"

    # Congestion Control
    local A_QDISC=$(ssh_run db "cat /proc/sys/net/core/default_qdisc 2>/dev/null")
    local A_CONGESTION=$(ssh_run db "cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null")

    check_config "net.core.default_qdisc" "$NET_CORE_DEFAULT_QDISC" "$A_QDISC"
    check_config "net.ipv4.tcp_congestion_control" "$NET_IPV4_TCP_CONGESTION_CONTROL" "$A_CONGESTION"

    # =========================================================================
    # DISK / RAID
    # =========================================================================
    print_category "Disk / RAID"

    # RAID chunk size (from mdadm)
    local RAID_ACTUAL=$(ssh_run db "sudo mdadm --detail /dev/md0 2>/dev/null | grep 'Chunk Size' | awk '{print \$4}'; sudo mdadm --detail /dev/md1 2>/dev/null | grep 'Chunk Size' | awk '{print \$4}'")
    local A_CHUNK_DATA=$(echo "$RAID_ACTUAL" | head -1)
    local A_CHUNK_WAL=$(echo "$RAID_ACTUAL" | tail -1)

    check_config "DATA RAID chunk" "$DATA_RAID_CHUNK" "$A_CHUNK_DATA"
    check_config "WAL RAID chunk" "$WAL_RAID_CHUNK" "$A_CHUNK_WAL"

    # Block device tuning (md arrays)
    local DISK_ACTUAL=$(ssh_run db "cat /sys/block/md0/queue/read_ahead_kb /sys/block/md1/queue/read_ahead_kb 2>/dev/null | tr '\n' ' '")
    read -r A_RA_DATA A_RA_WAL <<< "$DISK_ACTUAL"

    check_config "DATA read_ahead_kb" "$DATA_READ_AHEAD_KB" "$A_RA_DATA"
    check_config "WAL read_ahead_kb" "$WAL_READ_AHEAD_KB" "$A_RA_WAL"
    # Note: nr_requests not available for md (software RAID) - only physical devices

    # THP
    local A_THP=$(ssh_run db "cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null | grep -o '\[.*\]' | tr -d '[]'")
    check_config "transparent_hugepage" "$THP_ENABLED" "$A_THP"

    # =========================================================================
    # POSTGRESQL
    # =========================================================================
    print_category "PostgreSQL - Memory"

    local PG_MEM=$(ssh_run db "sudo -u postgres psql -t -A -c \"SELECT name || '=' || setting FROM pg_settings WHERE name IN ('shared_buffers','effective_cache_size','work_mem','maintenance_work_mem','huge_pages','max_connections') ORDER BY name;\" 2>/dev/null" | tr -d '\r')

    # Parse PostgreSQL settings
    local A_PG_EFFECTIVE_CACHE=$(echo "$PG_MEM" | grep "^effective_cache_size=" | cut -d= -f2 | tr -d ' ')
    local A_PG_HUGE_PAGES=$(echo "$PG_MEM" | grep "^huge_pages=" | cut -d= -f2 | tr -d ' ')
    local A_PG_MAINT_MEM=$(echo "$PG_MEM" | grep "^maintenance_work_mem=" | cut -d= -f2 | tr -d ' ')
    local A_PG_MAX_CONN=$(echo "$PG_MEM" | grep "^max_connections=" | cut -d= -f2 | tr -d ' ')
    local A_PG_SHARED=$(echo "$PG_MEM" | grep "^shared_buffers=" | cut -d= -f2 | tr -d ' ')
    local A_PG_WORK_MEM=$(echo "$PG_MEM" | grep "^work_mem=" | cut -d= -f2 | tr -d ' ')

    # Convert PostgreSQL units (8kB pages) to human readable
    local A_PG_SHARED_HR="$((${A_PG_SHARED:-0} * 8 / 1024 / 1024))GB"
    local A_PG_EFFECTIVE_HR="$((${A_PG_EFFECTIVE_CACHE:-0} * 8 / 1024 / 1024))GB"
    local A_PG_WORK_HR="$((${A_PG_WORK_MEM:-0} / 1024))MB"
    local A_PG_MAINT_HR="$((${A_PG_MAINT_MEM:-0} / 1024))MB"

    check_config "shared_buffers" "$PG_SHARED_BUFFERS" "$A_PG_SHARED_HR"
    check_config "effective_cache_size" "$PG_EFFECTIVE_CACHE_SIZE" "$A_PG_EFFECTIVE_HR"
    check_config "work_mem" "$PG_WORK_MEM" "$A_PG_WORK_HR"
    check_config "maintenance_work_mem" "$PG_MAINTENANCE_WORK_MEM" "$A_PG_MAINT_HR"
    check_config "huge_pages" "$PG_HUGE_PAGES" "$A_PG_HUGE_PAGES"
    check_config "max_connections" "$PG_MAX_CONNECTIONS" "$A_PG_MAX_CONN"

    print_category "PostgreSQL - WAL"

    local PG_WAL=$(ssh_run db "sudo -u postgres psql -t -A -c \"SELECT name || '=' || setting FROM pg_settings WHERE name IN ('wal_level','wal_compression','wal_sync_method','wal_buffers','wal_writer_delay','synchronous_commit','max_wal_size','min_wal_size') ORDER BY name;\" 2>/dev/null" | tr -d '\r')

    local A_MAX_WAL=$(echo "$PG_WAL" | grep "^max_wal_size=" | cut -d= -f2 | tr -d ' ')
    local A_MIN_WAL=$(echo "$PG_WAL" | grep "^min_wal_size=" | cut -d= -f2 | tr -d ' ')
    local A_SYNC_COMMIT=$(echo "$PG_WAL" | grep "^synchronous_commit=" | cut -d= -f2 | tr -d ' ')
    local A_WAL_BUFFERS=$(echo "$PG_WAL" | grep "^wal_buffers=" | cut -d= -f2 | tr -d ' ')
    local A_WAL_COMPRESS=$(echo "$PG_WAL" | grep "^wal_compression=" | cut -d= -f2 | tr -d ' ')
    local A_WAL_LEVEL=$(echo "$PG_WAL" | grep "^wal_level=" | cut -d= -f2 | tr -d ' ')
    local A_WAL_SYNC=$(echo "$PG_WAL" | grep "^wal_sync_method=" | cut -d= -f2 | tr -d ' ')
    local A_WAL_DELAY=$(echo "$PG_WAL" | grep "^wal_writer_delay=" | cut -d= -f2 | tr -d ' ')

    local A_WAL_BUF_HR="$((${A_WAL_BUFFERS:-0} * 8 / 1024))MB"
    local A_MAX_WAL_HR="${A_MAX_WAL}MB"
    local A_MIN_WAL_HR="${A_MIN_WAL}MB"

    # Normalize local values (1GB = 1024MB)
    local L_MAX_WAL_NUM=$(echo "$PG_MAX_WAL_SIZE" | sed 's/GB//' | sed 's/MB//')
    local L_MIN_WAL_NUM=$(echo "$PG_MIN_WAL_SIZE" | sed 's/GB//' | sed 's/MB//')
    [[ "$PG_MAX_WAL_SIZE" == *GB ]] && L_MAX_WAL_NUM=$((L_MAX_WAL_NUM * 1024))
    [[ "$PG_MIN_WAL_SIZE" == *GB ]] && L_MIN_WAL_NUM=$((L_MIN_WAL_NUM * 1024))
    local L_MAX_WAL="${L_MAX_WAL_NUM}"
    local L_MIN_WAL="${L_MIN_WAL_NUM}"

    check_config "wal_level" "$PG_WAL_LEVEL" "$A_WAL_LEVEL"
    check_config "wal_compression" "$PG_WAL_COMPRESSION" "$A_WAL_COMPRESS"
    check_config "wal_sync_method" "$PG_WAL_SYNC_METHOD" "$A_WAL_SYNC"
    check_config "wal_buffers" "$PG_WAL_BUFFERS" "$A_WAL_BUF_HR"
    check_config "wal_writer_delay" "$PG_WAL_WRITER_DELAY" "${A_WAL_DELAY}ms"
    check_config "synchronous_commit" "$PG_SYNCHRONOUS_COMMIT" "$A_SYNC_COMMIT"
    check_config "max_wal_size" "${L_MAX_WAL}MB" "$A_MAX_WAL_HR"
    check_config "min_wal_size" "${L_MIN_WAL}MB" "$A_MIN_WAL_HR"

    print_category "PostgreSQL - Checkpoint & BGWriter"

    local PG_CKPT=$(ssh_run db "sudo -u postgres psql -t -A -c \"SELECT name || '=' || setting FROM pg_settings WHERE name IN ('checkpoint_timeout','checkpoint_completion_target','bgwriter_delay','bgwriter_lru_maxpages','bgwriter_lru_multiplier','commit_delay','commit_siblings') ORDER BY name;\" 2>/dev/null" | tr -d '\r')

    local A_BGDELAY=$(echo "$PG_CKPT" | grep "^bgwriter_delay=" | cut -d= -f2 | tr -d ' ')
    local A_BGMAXPAGES=$(echo "$PG_CKPT" | grep "^bgwriter_lru_maxpages=" | cut -d= -f2 | tr -d ' ')
    local A_BGMULTIPLIER=$(echo "$PG_CKPT" | grep "^bgwriter_lru_multiplier=" | cut -d= -f2 | tr -d ' ')
    local A_CKPT_TIMEOUT=$(echo "$PG_CKPT" | grep "^checkpoint_timeout=" | cut -d= -f2 | tr -d ' ')
    local A_CKPT_TARGET=$(echo "$PG_CKPT" | grep "^checkpoint_completion_target=" | cut -d= -f2 | tr -d ' ')
    local A_COMMIT_DELAY=$(echo "$PG_CKPT" | grep "^commit_delay=" | cut -d= -f2 | tr -d ' ')
    local A_COMMIT_SIBLINGS=$(echo "$PG_CKPT" | grep "^commit_siblings=" | cut -d= -f2 | tr -d ' ')

    local L_CKPT_TIMEOUT=$(echo "$PG_CHECKPOINT_TIMEOUT" | sed 's/min//' | awk '{print $1 * 60}')

    check_config "checkpoint_timeout" "${L_CKPT_TIMEOUT}s" "${A_CKPT_TIMEOUT}s"
    check_config "checkpoint_completion_target" "$PG_CHECKPOINT_COMPLETION_TARGET" "$A_CKPT_TARGET"
    check_config "bgwriter_delay" "$PG_BGWRITER_DELAY" "${A_BGDELAY}ms"
    check_config "bgwriter_lru_maxpages" "$PG_BGWRITER_LRU_MAXPAGES" "$A_BGMAXPAGES"
    check_config "bgwriter_lru_multiplier" "$PG_BGWRITER_LRU_MULTIPLIER" "$A_BGMULTIPLIER"
    check_config "commit_delay" "$PG_COMMIT_DELAY" "$A_COMMIT_DELAY"
    check_config "commit_siblings" "$PG_COMMIT_SIBLINGS" "$A_COMMIT_SIBLINGS"

    print_category "PostgreSQL - Autovacuum"

    local PG_AV=$(ssh_run db "sudo -u postgres psql -t -A -c \"SELECT name || '=' || setting FROM pg_settings WHERE name IN ('autovacuum','track_counts','autovacuum_vacuum_scale_factor','autovacuum_analyze_scale_factor','autovacuum_vacuum_cost_limit','autovacuum_vacuum_cost_delay') ORDER BY name;\" 2>/dev/null" | tr -d '\r')

    local A_AUTOVACUUM=$(echo "$PG_AV" | grep "^autovacuum=" | cut -d= -f2 | tr -d ' ')
    local A_TRACK_COUNTS=$(echo "$PG_AV" | grep "^track_counts=" | cut -d= -f2 | tr -d ' ')
    local A_AV_VACUUM_SCALE=$(echo "$PG_AV" | grep "^autovacuum_vacuum_scale_factor=" | cut -d= -f2 | tr -d ' ')
    local A_AV_ANALYZE_SCALE=$(echo "$PG_AV" | grep "^autovacuum_analyze_scale_factor=" | cut -d= -f2 | tr -d ' ')
    local A_AV_COST_LIMIT=$(echo "$PG_AV" | grep "^autovacuum_vacuum_cost_limit=" | cut -d= -f2 | tr -d ' ')
    local A_AV_COST_DELAY=$(echo "$PG_AV" | grep "^autovacuum_vacuum_cost_delay=" | cut -d= -f2 | tr -d ' ')

    check_config "autovacuum" "$PG_AUTOVACUUM" "$A_AUTOVACUUM"
    check_config "track_counts" "$PG_TRACK_COUNTS" "$A_TRACK_COUNTS"
    check_config "autovacuum_vacuum_scale_factor" "$PG_AUTOVACUUM_VACUUM_SCALE_FACTOR" "$A_AV_VACUUM_SCALE"
    check_config "autovacuum_analyze_scale_factor" "$PG_AUTOVACUUM_ANALYZE_SCALE_FACTOR" "$A_AV_ANALYZE_SCALE"
    check_config "autovacuum_vacuum_cost_limit" "$PG_AUTOVACUUM_VACUUM_COST_LIMIT" "$A_AV_COST_LIMIT"
    check_config "autovacuum_vacuum_cost_delay" "$PG_AUTOVACUUM_VACUUM_COST_DELAY" "${A_AV_COST_DELAY}ms"

    print_category "PostgreSQL - Logging & Query"

    local PG_LOG=$(ssh_run db "sudo -u postgres psql -t -A -c \"SELECT name || '=' || setting FROM pg_settings WHERE name IN ('logging_collector','log_min_duration_statement','log_checkpoints','log_lock_waits','log_temp_files','log_autovacuum_min_duration','jit') ORDER BY name;\" 2>/dev/null" | tr -d '\r')

    local A_LOGGING_COLLECTOR=$(echo "$PG_LOG" | grep "^logging_collector=" | cut -d= -f2 | tr -d ' ')
    local A_LOG_MIN_DUR=$(echo "$PG_LOG" | grep "^log_min_duration_statement=" | cut -d= -f2 | tr -d ' ')
    local A_LOG_CHECKPOINTS=$(echo "$PG_LOG" | grep "^log_checkpoints=" | cut -d= -f2 | tr -d ' ')
    local A_LOG_LOCK_WAITS=$(echo "$PG_LOG" | grep "^log_lock_waits=" | cut -d= -f2 | tr -d ' ')
    local A_LOG_TEMP_FILES=$(echo "$PG_LOG" | grep "^log_temp_files=" | cut -d= -f2 | tr -d ' ')
    local A_LOG_AV_MIN_DUR=$(echo "$PG_LOG" | grep "^log_autovacuum_min_duration=" | cut -d= -f2 | tr -d ' ')
    local A_JIT=$(echo "$PG_LOG" | grep "^jit=" | cut -d= -f2 | tr -d ' ')

    check_config "logging_collector" "$PG_LOGGING_COLLECTOR" "$A_LOGGING_COLLECTOR"
    check_config "log_min_duration_statement" "$PG_LOG_MIN_DURATION_STATEMENT" "$A_LOG_MIN_DUR"
    check_config "log_checkpoints" "$PG_LOG_CHECKPOINTS" "$A_LOG_CHECKPOINTS"
    check_config "log_lock_waits" "$PG_LOG_LOCK_WAITS" "$A_LOG_LOCK_WAITS"
    check_config "log_temp_files" "$PG_LOG_TEMP_FILES" "$A_LOG_TEMP_FILES"
    check_config "log_autovacuum_min_duration" "$PG_LOG_AUTOVACUUM_MIN_DURATION" "$A_LOG_AV_MIN_DUR"
    check_config "jit" "$PG_JIT" "$A_JIT"

    # =========================================================================
    # PGCAT
    # =========================================================================
    print_category "PgCat"

    local PGCAT_REMOTE=$(ssh_run proxy "cat /etc/pgcat/pgcat.toml 2>/dev/null")
    local PGCAT_LOCAL=$(cat "$CONFIG_DIR/pgcat.toml" 2>/dev/null)

    # Extract key PgCat settings
    get_toml_value() {
        echo "$1" | grep "^$2 *=" | head -1 | cut -d= -f2 | tr -d ' "'
    }

    local L_PGCAT_WORKERS=$(get_toml_value "$PGCAT_LOCAL" "worker_threads")
    local A_PGCAT_WORKERS=$(get_toml_value "$PGCAT_REMOTE" "worker_threads")
    local L_PGCAT_POOL_SIZE=$(get_toml_value "$PGCAT_LOCAL" "pool_size")
    local A_PGCAT_POOL_SIZE=$(get_toml_value "$PGCAT_REMOTE" "pool_size")
    local L_PGCAT_MIN_POOL=$(get_toml_value "$PGCAT_LOCAL" "min_pool_size")
    local A_PGCAT_MIN_POOL=$(get_toml_value "$PGCAT_REMOTE" "min_pool_size")
    local L_PGCAT_PARSER=$(get_toml_value "$PGCAT_LOCAL" "query_parser_enabled")
    local A_PGCAT_PARSER=$(get_toml_value "$PGCAT_REMOTE" "query_parser_enabled")
    local L_PGCAT_IDLE=$(get_toml_value "$PGCAT_LOCAL" "idle_timeout")
    local A_PGCAT_IDLE=$(get_toml_value "$PGCAT_REMOTE" "idle_timeout")

    check_config "worker_threads" "$L_PGCAT_WORKERS" "$A_PGCAT_WORKERS"
    check_config "pool_size" "$L_PGCAT_POOL_SIZE" "$A_PGCAT_POOL_SIZE"
    check_config "min_pool_size" "$L_PGCAT_MIN_POOL" "$A_PGCAT_MIN_POOL"
    check_config "query_parser_enabled" "$L_PGCAT_PARSER" "$A_PGCAT_PARSER"
    check_config "idle_timeout" "$L_PGCAT_IDLE" "$A_PGCAT_IDLE"

    # =========================================================================
    # SUMMARY
    # =========================================================================
    echo ""
    printf '%100s\n' | tr ' ' '='
    if [ $MISMATCH_COUNT -eq 0 ]; then
        echo -e "${GREEN}✓ All configurations matched!${NC}"
    else
        echo -e "${RED}✗ Found $MISMATCH_COUNT mismatched configurations${NC}"
        echo -e "Run: ${YELLOW}./bootstrap.sh apply all${NC} to sync configs"
    fi
    echo ""

    return $MISMATCH_COUNT
}

cmd_benchmark() {
    local SCENARIO_ID="${1:-11}"
    local MODE="${2:-pgcat}"  # pgcat or direct (default: pgcat per CLAUDE.MD)
    cmd_sync

    local DB_IP=$(jq -r '.db_node.value.private_ip' "$INFRA_JSON")
    local PROXY_IP=$(jq -r '.proxy_node.value.private_ip' "$INFRA_JSON")

    if [ "$MODE" == "pgcat" ]; then
        log "=== BENCHMARK: Scenario $SCENARIO_ID via PgCat ($PROXY_IP:6432 -> $DB_IP) ==="
        ssh_run proxy "sudo python3 $REMOTE_HOME/scripts/bench.py $SCENARIO_ID --host $PROXY_IP --port 6432 --db-host $DB_IP"
    else
        log "=== BENCHMARK: Scenario $SCENARIO_ID Direct ($DB_IP:5432) ==="
        ssh_run proxy "sudo python3 $REMOTE_HOME/scripts/bench.py $SCENARIO_ID --host $DB_IP --db-host $DB_IP"
    fi
    cmd_results
}

cmd_bench_all() {
    local MODE="${1:-pgcat}"  # pgcat or direct
    local SCENARIOS="${2:-11-15}"  # default postgres scenarios

    log "=== BATCH BENCHMARK: Scenarios $SCENARIOS via $MODE ==="
    cmd_sync

    local DB_IP=$(jq -r '.db_node.value.private_ip' "$INFRA_JSON")
    local PROXY_IP=$(jq -r '.proxy_node.value.private_ip' "$INFRA_JSON")

    # Parse scenario range (e.g., 11-15 or 11,12,14 or 11)
    local SCENARIO_LIST=""
    if [[ "$SCENARIOS" == *"-"* ]]; then
        # Range format: 11-15
        local START=$(echo "$SCENARIOS" | cut -d'-' -f1)
        local END=$(echo "$SCENARIOS" | cut -d'-' -f2)
        SCENARIO_LIST=$(seq $START $END)
    elif [[ "$SCENARIOS" == *","* ]]; then
        # Comma format: 11,12,14
        SCENARIO_LIST=$(echo "$SCENARIOS" | tr ',' ' ')
    else
        # Single: 11
        SCENARIO_LIST="$SCENARIOS"
    fi

    local TOTAL=$(echo $SCENARIO_LIST | wc -w | tr -d ' ')
    local COUNT=0

    for SCENARIO_ID in $SCENARIO_LIST; do
        COUNT=$((COUNT + 1))
        log "[$COUNT/$TOTAL] Running scenario $SCENARIO_ID..."

        if [ "$MODE" == "pgcat" ]; then
            ssh_run proxy "sudo python3 $REMOTE_HOME/scripts/bench.py $SCENARIO_ID --host $PROXY_IP --port 6432 --db-host $DB_IP" || warn "Scenario $SCENARIO_ID failed"
        else
            ssh_run proxy "sudo python3 $REMOTE_HOME/scripts/bench.py $SCENARIO_ID --host $DB_IP --db-host $DB_IP" || warn "Scenario $SCENARIO_ID failed"
        fi

        # Brief pause between scenarios
        [ $COUNT -lt $TOTAL ] && sleep 5
    done

    log "=== BATCH COMPLETE: $COUNT scenarios ==="
    cmd_results
}

cmd_results() {
    log "=== RESULTS ==="
    rsync_from_remote proxy
    ls -lt "$LOCAL_RESULTS"/*.md 2>/dev/null | head -n 3
}

cmd_ssh() {
    local target=${1:-db}
    local ip=""
    [ "$target" == "db" ] && ip=$(get_db_ip) || ip=$(get_proxy_ip)
    ssh $SSH_OPTS "ubuntu@$ip"
}

cmd_destroy() {
    log "=== DESTROYING INFRASTRUCTURE ==="
    cd "$TERRAFORM_DIR"
    terraform destroy -auto-approve
    rm -f "$INFRA_JSON"
    log "Infrastructure destroyed"
}

cmd_cleanup() {
    log "=== CLEANING UP REMOTE PROCESSES ==="
    ssh_run db "sudo pkill -f 'bench.py|pgbench|fio|iostat|mpstat' 2>/dev/null || true"
    ssh_run proxy "sudo pkill -f 'bench.py|pgbench|fio|iostat|mpstat' 2>/dev/null || true"
    log "Cleanup complete"
}

cmd_status() {
    if [ ! -f "$INFRA_JSON" ]; then warn "No infrastructure provisioned"; return; fi
    log "=== STATUS ==="
    echo "Topology: $(jq -r '.topology.value' "$INFRA_JSON")"
    echo "DB Node:    $(get_db_ip) (vCPU: $(jq -r '.db_node.value.vcpu' "$INFRA_JSON"), RAM: $(jq -r '.db_node.value.ram_gb' "$INFRA_JSON")GB)"
    echo "Proxy Node: $(get_proxy_ip) (vCPU: $(jq -r '.proxy_node.value.vcpu' "$INFRA_JSON"), RAM: $(jq -r '.proxy_node.value.ram_gb' "$INFRA_JSON")GB)"
}

# =============================================================================
# AMI BAKING
# =============================================================================

# Helper: bake single AMI (reduces duplication)
bake_one_ami() {
    local ami_type="$1"      # db or proxy
    local instance_id="$2"
    local ami_name="$3"
    local description="$4"

    log "Baking $ami_type AMI from instance: $instance_id"
    log "  AMI Name: $ami_name"

    # Check if exists
    local existing=$(aws ec2 describe-images --profile "$AWS_PROFILE" --region "$AWS_REGION" \
        --owners self --filters "Name=name,Values=${ami_name}" \
        --query 'Images[0].ImageId' --output text 2>/dev/null)

    if [ -n "$existing" ] && [ "$existing" != "None" ]; then
        warn "AMI '$ami_name' already exists: $existing"
        read -p "Delete and recreate? (y/N): " confirm
        if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
            aws ec2 deregister-image --profile "$AWS_PROFILE" --region "$AWS_REGION" --image-id "$existing"
            sleep 2
        else
            echo "$ami_type:$existing"
            return 0
        fi
    fi

    # Create AMI
    local ami_id=$(aws ec2 create-image --profile "$AWS_PROFILE" --region "$AWS_REGION" \
        --instance-id "$instance_id" --name "$ami_name" --description "$description" \
        --no-reboot --query 'ImageId' --output text)

    [ -z "$ami_id" ] && error "Failed to create $ami_type AMI"
    log "  Created $ami_type AMI: $ami_id"
    echo "$ami_type:$ami_id"
}

cmd_bake() {
    local target="${1:-all}"
    local version="${2:-$(date +%Y%m%d)}"

    log "=== BAKING AMI ==="

    local db_instance_id=$(jq -r '.db_node.value.instance_id' "$INFRA_JSON")
    local proxy_instance_id=$(jq -r '.proxy_node.value.instance_id' "$INFRA_JSON")
    [ -z "$db_instance_id" ] || [ "$db_instance_id" == "null" ] && error "No infra. Run 'provision' first."

    declare -a NEW_AMIS=()

    # Bake requested AMIs
    [[ "$target" == "all" || "$target" == "db" ]] && \
        NEW_AMIS+=($(bake_one_ami "db" "$db_instance_id" "postgres-r8g-golden-${version}" "PostgreSQL golden AMI"))
    [[ "$target" == "all" || "$target" == "proxy" ]] && \
        NEW_AMIS+=($(bake_one_ami "proxy" "$proxy_instance_id" "proxy-c8g-golden-${version}" "Proxy/PgCat golden AMI"))

    # Wait for AMIs
    log "Waiting for AMIs (5-15 minutes)..."
    for entry in "${NEW_AMIS[@]}"; do
        local t="${entry%%:*}" id="${entry##*:}"
        log "  Waiting for $t: $id"
        aws ec2 wait image-available --profile "$AWS_PROFILE" --region "$AWS_REGION" --image-ids "$id" || \
            error "Timeout waiting for $t AMI"
        log "  $t AMI ready: $id"
    done

    # Update terraform
    local TF_MAIN="$TERRAFORM_DIR/main.tf"
    log "Updating Terraform..."
    for entry in "${NEW_AMIS[@]}"; do
        local t="${entry%%:*}" id="${entry##*:}"
        if [ "$t" == "db" ]; then
            sed -i.bak "s|default = \"ami-[a-z0-9]*\"  # postgres-|default = \"$id\"  # postgres-|" "$TF_MAIN"
        else
            sed -i.bak "s|default = \"ami-[a-z0-9]*\"  # proxy-|default = \"$id\"  # proxy-|" "$TF_MAIN"
        fi
        log "  Updated ${t}_ami_id -> $id"
    done
    rm -f "${TF_MAIN}.bak"

    log ""
    log "=== BAKING COMPLETE ==="
    printf "  %s\n" "${NEW_AMIS[@]}"
    log "Next: git diff $TF_MAIN && git commit"
}

cmd_ami_list() {
    log "=== GOLDEN AMIs ==="
    for prefix in postgres proxy; do
        echo -e "\n${BLUE}### ${prefix}-* AMIs${NC}"
        aws ec2 describe-images --profile "$AWS_PROFILE" --region "$AWS_REGION" \
            --owners self --filters "Name=name,Values=${prefix}-*" \
            --query 'Images[*].[ImageId,Name,CreationDate,State]' --output table
    done
}

cmd_ami_delete() {
    [ -z "$1" ] && error "Usage: ./bootstrap.sh ami-delete <ami-id>"
    local ami_id="$1"

    log "Deregistering AMI: $ami_id"
    local snapshots=$(aws ec2 describe-images --profile "$AWS_PROFILE" --region "$AWS_REGION" \
        --image-ids "$ami_id" --query 'Images[0].BlockDeviceMappings[*].Ebs.SnapshotId' --output text 2>/dev/null)

    aws ec2 deregister-image --profile "$AWS_PROFILE" --region "$AWS_REGION" --image-id "$ami_id" || \
        error "Failed to deregister AMI"

    # Delete snapshots
    for snap in $snapshots; do
        [ -n "$snap" ] && [ "$snap" != "None" ] && \
            aws ec2 delete-snapshot --profile "$AWS_PROFILE" --region "$AWS_REGION" --snapshot-id "$snap" 2>/dev/null
    done
    log "Done."
}

cmd_scenarios() {
    log "=== AVAILABLE BENCHMARK SCENARIOS ==="
    echo ""

    local SCENARIOS_FILE="$SCRIPT_DIR/scripts/scenarios.json"
    [ ! -f "$SCENARIOS_FILE" ] && error "scenarios.json not found"

    # FIO scenarios (1-10) - single jq call
    echo -e "${BLUE}### FIO Disk Benchmarks (1-10)${NC}"
    printf "%-4s | %-22s | %-6s | %s\n" "ID" "NAME" "TARGET" "DESCRIPTION"
    printf '%80s\n' | tr ' ' '-'
    jq -r '.scenarios | to_entries[] | select(.key | test("^[1-9]$|^10$")) |
        "\(.key)|\(.value.name)|\(.value.target_disk // "data" | ascii_upcase)|\(.value.desc)"' \
        "$SCENARIOS_FILE" | sort -t'|' -k1 -n | while IFS='|' read -r id name target desc; do
        printf "%-4s | %-22s | %-6s | %s\n" "$id" "$name" "$target" "$desc"
    done

    # pgbench scenarios (11-15) - single jq call
    echo ""
    echo -e "${BLUE}### PostgreSQL pgbench Benchmarks (11-15)${NC}"
    printf "%-4s | %-22s | %-8s | %-8s | %s\n" "ID" "NAME" "CLIENTS" "PROTOCOL" "DESCRIPTION"
    printf '%100s\n' | tr ' ' '-'
    jq -r '.scenarios | to_entries[] | select(.key | test("^1[1-5]$")) |
        "\(.key)|\(.value.name)|\(.value.clients)/\(.value.clients_pgcat)|\(.value.desc)"' \
        "$SCENARIOS_FILE" | sort -t'|' -k1 -n | while IFS='|' read -r id name clients desc; do
        local protocol="simple"
        case $id in 12) protocol="simple -S";; 13) protocol="simple -C";; 15) protocol="prepared";; esac
        printf "%-4s | %-22s | %-8s | %-8s | %s\n" "$id" "$name" "$clients" "$protocol" "$desc"
    done

    # Sysbench scenarios (21-23) - single jq call
    echo ""
    echo -e "${BLUE}### Sysbench TPC-C Benchmarks (21-23)${NC}"
    printf "%-4s | %-22s | %-8s | %s\n" "ID" "NAME" "CLIENTS" "DESCRIPTION"
    printf '%80s\n' | tr ' ' '-'
    jq -r '.scenarios | to_entries[] | select(.key | test("^2[1-3]$")) |
        "\(.key)|\(.value.name)|\(.value.clients)/\(.value.clients_pgcat)|\(.value.desc)"' \
        "$SCENARIOS_FILE" | sort -t'|' -k1 -n | while IFS='|' read -r id name clients desc; do
        printf "%-4s | %-22s | %-8s | %s\n" "$id" "$name" "$clients" "$desc"
    done

    echo ""
    echo -e "${YELLOW}Note: Clients shown as direct/pgcat. Use -M prepared only with direct mode.${NC}"
    echo ""
}

cmd_help() {
    cat << 'EOF'

Usage: ./bootstrap.sh <command> [args]

Commands:
  provision            Terraform apply + initial setup
  sync                 Sync local scripts to remote
  apply [TARGET]       Sync + apply configs
                       TARGET: all|os|disk|tcp|postgres|pgcat (default: all)
  verify               Compare local vs actual configs (table view)
  scenarios            List all benchmark scenarios with descriptions
  benchmark ID [MODE]  Run single benchmark
                       MODE: pgcat|direct (default: pgcat)
  bench-all [MODE] [SCENARIOS]
                       Run batch benchmarks
                       MODE: pgcat|direct (default: pgcat)
                       SCENARIOS: 11-15 or 11,12,14 (default: 11-15)
  results              Sync results from remote to local
  ssh [db|proxy]       SSH into instance (default: db)
  status               Show infrastructure status
  cleanup              Kill remote benchmark processes
  destroy              Destroy infrastructure (no prompt)

AMI Management:
  bake [TARGET] [VER]  Bake golden AMI from running instance
                       TARGET: all|db|proxy (default: all)
                       VER: version suffix (default: YYYYMMDD)
  ami-list             List all golden AMIs (postgres-*, proxy-*)
  ami-delete <AMI-ID>  Delete AMI and associated snapshots

Examples:
  ./bootstrap.sh provision               # Full provision + setup
  ./bootstrap.sh scenarios               # List all benchmark scenarios
  ./bootstrap.sh apply postgres          # Apply only PostgreSQL config
  ./bootstrap.sh apply all               # Apply OS + Disk + PG + PgCat
  ./bootstrap.sh benchmark 11            # Single scenario via PgCat
  ./bootstrap.sh benchmark 11 direct     # Single scenario direct to PG
  ./bootstrap.sh bench-all               # Run scenarios 11-15 via PgCat
  ./bootstrap.sh bench-all pgcat 11-15   # Same as above
  ./bootstrap.sh bench-all direct 21-23  # Sysbench scenarios direct

AMI Examples:
  ./bootstrap.sh bake                    # Bake both db + proxy AMIs
  ./bootstrap.sh bake db                 # Bake only DB AMI
  ./bootstrap.sh bake all v4             # Bake with custom version suffix
  ./bootstrap.sh ami-list                # List all golden AMIs
  ./bootstrap.sh ami-delete ami-xxx      # Delete old AMI + snapshots

Config Layers (edit locally, then apply):
  scripts/config/os.env       -> apply os      (vm.*, kernel.*)
  scripts/config/base.env     -> apply disk    (read_ahead, mount)
  scripts/config/primary.env  -> apply postgres (PG_*)
  scripts/config/pgcat.toml   -> apply pgcat   (pooler config)

EOF
}

# =============================================================================
# MAIN
# =============================================================================

cmd_usage_error() {
    local error_type="$1"
    local bad_value="$2"

    echo -e "${RED}Error: Unknown $error_type '$bad_value'${NC}"
    echo ""

    case "$error_type" in
        command)
            echo "Valid commands:"
            echo "  provision, sync, apply, setup, verify, scenarios,"
            echo "  benchmark, bench-all, results, ssh, status, cleanup, destroy,"
            echo "  bake, ami-list, ami-delete, help"
            ;;
        "apply target")
            echo "Valid apply targets:"
            echo "  all      - Apply all configs (OS + Disk + PostgreSQL + PgCat)"
            echo "  os       - Apply OS config (vm.*, kernel.*, tcp.*)"
            echo "  disk     - Apply disk/RAID tuning"
            echo "  tcp      - Apply TCP settings only"
            echo "  postgres - Apply PostgreSQL config"
            echo "  pgcat    - Apply PgCat pooler config"
            ;;
        "benchmark mode")
            echo "Valid benchmark modes:"
            echo "  pgcat    - Run via PgCat pooler (port 6432) [default]"
            echo "  direct   - Run directly to PostgreSQL (port 5432)"
            ;;
        "ssh target")
            echo "Valid ssh targets:"
            echo "  db       - SSH to database node [default]"
            echo "  proxy    - SSH to proxy node"
            ;;
        "bake target")
            echo "Valid bake targets:"
            echo "  all      - Bake both DB and Proxy AMIs [default]"
            echo "  db       - Bake only DB AMI"
            echo "  proxy    - Bake only Proxy AMI"
            ;;
    esac

    echo ""
    echo "Run './bootstrap.sh help' for full usage information."
    exit 1
}

case "${1:-help}" in
    provision)  cmd_provision ;;
    sync)       cmd_sync ;;
    apply)
        case "${2:-all}" in
            all|os|disk|tcp|postgres|db|pgcat|proxy) cmd_apply "$2" ;;
            *) cmd_usage_error "apply target" "$2" ;;
        esac
        ;;
    setup)      cmd_setup ;;
    verify)     cmd_verify ;;
    scenarios)  cmd_scenarios ;;
    benchmark)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Missing scenario ID${NC}"
            echo ""
            echo "Usage: ./bootstrap.sh benchmark <ID> [MODE]"
            echo ""
            echo "Run './bootstrap.sh scenarios' to see available scenarios."
            exit 1
        fi
        case "${3:-pgcat}" in
            pgcat|direct) cmd_benchmark "$2" "$3" ;;
            *) cmd_usage_error "benchmark mode" "$3" ;;
        esac
        ;;
    bench-all)
        case "${2:-pgcat}" in
            pgcat|direct) cmd_bench_all "$2" "$3" ;;
            *) cmd_usage_error "benchmark mode" "$2" ;;
        esac
        ;;
    results)    cmd_results ;;
    ssh)
        case "${2:-db}" in
            db|proxy) cmd_ssh "$2" ;;
            *) cmd_usage_error "ssh target" "$2" ;;
        esac
        ;;
    status)     cmd_status ;;
    cleanup)    cmd_cleanup ;;
    destroy)    cmd_destroy ;;
    # AMI Management
    bake)
        case "${2:-all}" in
            all|db|proxy) cmd_bake "$2" "$3" ;;
            *) cmd_usage_error "bake target" "$2" ;;
        esac
        ;;
    ami-list)   cmd_ami_list ;;
    ami-delete) cmd_ami_delete "$2" ;;
    help)       cmd_help ;;
    *)          cmd_usage_error "command" "$1" ;;
esac
