#!/bin/bash
# =============================================================================
# scripts/setup/all.sh - Master Setup Entry Point
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="/tmp/setup_all.log"

log() { echo -e "\033[0;32m[setup]\033[0m $1" | tee -a "$LOG_FILE"; }
error() { echo -e "\033[0;31m[error]\033[0m $1" | tee -a "$LOG_FILE"; exit 1; }

# Parse arguments
VCPU=""
RAM_GB=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --vcpu) VCPU="$2"; shift ;;
        --ram) RAM_GB="$2"; shift ;;
        *) error "Unknown parameter: $1" ;;
    esac
    shift
done

log "Starting complete setup sequence..."

# 1. Basics & Deps
log "[1/6] Installing dependencies..."
"$SCRIPT_DIR/00-deps.sh"

# 2. OS & Tuning (Always run even on proxy)
log "[2/6] OS Tuning..."
"$SCRIPT_DIR/01-os-tuning.sh"

# 3. Disk & RAID (Only if multiple NVMe disks detected)
NVME_COUNT=$(lsblk -d -n -o NAME | grep -c nvme || echo 0)
if [ "$NVME_COUNT" -gt 1 ]; then
    log "[3/6] Multiple NVMe detected. Setting up RAID and Disk tuning..."
    "$SCRIPT_DIR/02-raid-setup.sh"
    "$SCRIPT_DIR/03-disk-tuning.sh"
else
    log "[3/6] Skipping RAID/Disk tuning (Only $NVME_COUNT NVMe disks found)."
fi

# 4. PostgreSQL (Only if on DB node/required)
if [ -n "$VCPU" ] && [ -n "$RAM_GB" ]; then
    log "[4/6] PostgreSQL Installation & Dynamic Config..."
    "$SCRIPT_DIR/04-postgres.sh"
    
    log "[5/6] Calculating Dynamic Config (vCPU=$VCPU, RAM=${RAM_GB}GB)..."
    python3 "$SCRIPT_DIR/../config/calculate.py" --apply --vcpu "$VCPU" --ram "$RAM_GB"
    systemctl restart postgresql-bench
    
    log "[6/6] Initializing pgbench..."
    "$SCRIPT_DIR/05-pgbench-init.sh"
else
    log "[4/6] Skipping PostgreSQL setup (Missing vcpu/ram args, likely Proxy node)."
fi

log "Setup sequence complete!"
