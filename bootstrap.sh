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
info() { echo -e "${BLUE}[bootstrap]${NC} $1"; }

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
    log "=== VERIFYING ==="
    ssh_run db "sudo $REMOTE_HOME/scripts/tools/verify-config.sh"
}

cmd_benchmark() {
    local SCENARIO_ID="${1:-11}"
    local MODE="${2:-direct}"  # direct or pgcat
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
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$TERRAFORM_DIR"
        terraform destroy -auto-approve
        rm -f "$INFRA_JSON"
        log "Infrastructure destroyed"
    else
        log "Cancelled"
    fi
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

cmd_help() {
    cat << 'EOF'

Usage: ./bootstrap.sh <command> [args]

Commands:
  provision          Terraform apply + initial setup
  sync               Sync local scripts to remote
  verify             Verify config on remote
  benchmark ID [MODE] Run benchmark (MODE: direct|pgcat, default: direct)
  results            Sync results from remote to local
  ssh [db|proxy]     SSH into instance (default: db)
  status             Show infrastructure status
  cleanup            Kill remote benchmark processes
  destroy            Destroy infrastructure

Examples:
  ./bootstrap.sh benchmark 11-15         # Direct to PostgreSQL
  ./bootstrap.sh benchmark 11-15 pgcat   # Via PgCat pooler

EOF
}

# =============================================================================
# MAIN
# =============================================================================

case "${1:-help}" in
    provision) cmd_provision ;;
    sync)      cmd_sync ;;
    setup)     cmd_setup ;;
    verify)    cmd_verify ;;
    benchmark) cmd_benchmark "$2" ;;
    results)   cmd_results ;;
    ssh)       cmd_ssh "$2" ;;
    status)    cmd_status ;;
    cleanup)   cmd_cleanup ;;
    destroy)   cmd_destroy ;;
    help)      cmd_help ;;
    *)         echo "Usage: $0 {provision|sync|setup|verify|benchmark|results|ssh|status|cleanup|destroy|help}"; exit 1 ;;
esac
