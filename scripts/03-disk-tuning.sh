#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.env"

LOG_PREFIX="[03-disk-tuning]"

log() { echo "$LOG_PREFIX $1"; }
log_ok() { echo "$LOG_PREFIX ✓ $1"; }
log_fail() { echo "$LOG_PREFIX ✗ $1"; }
log_warn() { echo "$LOG_PREFIX ⚠ $1"; }

assert_equal() {
    local name=$1 expected=$2 actual=$3
    if [ "$expected" != "$actual" ]; then
        log_fail "$name: expected=$expected actual=$actual"
        return 1
    fi
    log_ok "$name = $actual"
    return 0
}

get_sysfs_value() {
    local path=$1
    if [ -f "$path" ]; then
        cat "$path" 2>/dev/null | tr -d '[]' | awk '{print $1}'
    else
        echo ""
    fi
}

set_sysfs_value() {
    local path=$1
    local value=$2
    local name=$3
    local required=${4:-true}  # Optional: false = non-fatal failure

    if [ ! -f "$path" ]; then
        if [ "$required" = "true" ]; then
            log_warn "$name: $path does not exist"
            return 1
        else
            log_warn "$name: $path does not exist (optional, skipping)"
            return 0
        fi
    fi

    local current=$(get_sysfs_value "$path")
    if [ "$current" = "$value" ]; then
        log_ok "$name already set to $value"
        return 0
    fi

    if echo "$value" > "$path" 2>/dev/null; then
        log_ok "$name: $current -> $value"
        return 0
    else
        if [ "$required" = "true" ]; then
            log_warn "$name: failed to set $value (current: $current)"
            return 1
        else
            log_warn "$name: cannot change (hardware limit, current: $current)"
            return 0
        fi
    fi
}

get_disks_by_size() {
    local size_gb=$1
    lsblk -b -d -n -o NAME,SIZE 2>/dev/null | awk -v size="$((size_gb * 1073741824))" '$2 == size {print $1}'
}

preflight() {
    log "=== PRE-FLIGHT CHECKS ==="

    if [ "$(id -u)" -ne 0 ]; then
        log_fail "Script phải chạy với root"
        exit 1
    fi
    log_ok "Running as root"

    if [ ! -e "$DATA_RAID_DEVICE" ]; then
        log_fail "$DATA_RAID_DEVICE does not exist. Run 02-raid-setup.sh first"
        exit 1
    fi
    log_ok "$DATA_RAID_DEVICE exists"

    if [ ! -e "$WAL_RAID_DEVICE" ]; then
        log_fail "$WAL_RAID_DEVICE does not exist. Run 02-raid-setup.sh first"
        exit 1
    fi
    log_ok "$WAL_RAID_DEVICE exists"
}

tune_block_device() {
    local devname=$1
    local role=$2
    local scheduler read_ahead nr_requests max_sectors rq_affinity add_random nomerges

    if [ "$role" = "data" ]; then
        scheduler=$DATA_SCHEDULER
        read_ahead=$DATA_READ_AHEAD_KB
        nr_requests=$DATA_NR_REQUESTS
        max_sectors=$DATA_MAX_SECTORS_KB
        rq_affinity=$DATA_RQ_AFFINITY
        add_random=$DATA_ADD_RANDOM
        nomerges=$DATA_NOMERGES
    else
        scheduler=$WAL_SCHEDULER
        read_ahead=$WAL_READ_AHEAD_KB
        nr_requests=$WAL_NR_REQUESTS
        max_sectors=$WAL_MAX_SECTORS_KB
        rq_affinity=$WAL_RQ_AFFINITY
        add_random=$WAL_ADD_RANDOM
        nomerges=$WAL_NOMERGES
    fi

    local syspath="/sys/block/$devname/queue"

    if [ ! -d "$syspath" ]; then
        log_warn "$devname: $syspath does not exist"
        return 1
    fi

    log "Tuning $devname ($role)..."

    # IMPORTANT: Set rotational FIRST because it resets read_ahead_kb to default
    echo 0 > "/sys/block/$devname/queue/rotational" 2>/dev/null || true

    # scheduler: optional - MD devices don't have scheduler (handled by underlying disks)
    set_sysfs_value "$syspath/scheduler" "$scheduler" "$devname/scheduler" "false"
    # read_ahead_kb MUST be set AFTER rotational (which resets it)
    set_sysfs_value "$syspath/read_ahead_kb" "$read_ahead" "$devname/read_ahead_kb"
    # nr_requests: optional - NVMe devices may not allow changing (hardware limit)
    # Also MD devices may not have nr_requests
    set_sysfs_value "$syspath/nr_requests" "$nr_requests" "$devname/nr_requests" "false"
    # max_sectors_kb: optional - MD devices may have different limits
    set_sysfs_value "$syspath/max_sectors_kb" "$max_sectors" "$devname/max_sectors_kb" "false"
    set_sysfs_value "$syspath/rq_affinity" "$rq_affinity" "$devname/rq_affinity" "false"
    set_sysfs_value "$syspath/add_random" "$add_random" "$devname/add_random" "false"
    set_sysfs_value "$syspath/nomerges" "$nomerges" "$devname/nomerges" "false"
}

tune_md_device() {
    local devname=$1

    local mdpath="/sys/block/$devname/md"
    if [ ! -d "$mdpath" ]; then
        log_warn "$devname: not an MD device"
        return 1
    fi

    log "Tuning MD device $devname..."

    # stripe_cache_size only exists for RAID5/6, not for RAID10
    # Mark as optional to avoid failures on RAID10
    if [ -f "$mdpath/stripe_cache_size" ]; then
        set_sysfs_value "$mdpath/stripe_cache_size" "$MD_STRIPE_CACHE_SIZE" "$devname/stripe_cache_size"
    else
        log_ok "$devname/stripe_cache_size: N/A (RAID10 doesn't have stripe cache)"
    fi
}

apply_tuning() {
    log "=== TUNING UNDERLYING DISKS ==="

    local data_disks=$(get_disks_by_size "$DATA_DISK_SIZE_GB")
    for disk in $data_disks; do
        tune_block_device "$disk" "data"
    done

    local wal_disks=$(get_disks_by_size "$WAL_DISK_SIZE_GB")
    for disk in $wal_disks; do
        tune_block_device "$disk" "wal"
    done

    log "=== TUNING RAID DEVICES ==="

    local data_md=$(basename "$DATA_RAID_DEVICE")
    tune_block_device "$data_md" "data"
    tune_md_device "$data_md"

    local wal_md=$(basename "$WAL_RAID_DEVICE")
    tune_block_device "$wal_md" "wal"
    tune_md_device "$wal_md"
}

create_udev_rules() {
    log "=== CREATING UDEV RULES ==="

    local rules_file="/etc/udev/rules.d/99-disk-tuning.rules"

    cat > "$rules_file" << EOF
# DATA RAID device tuning
ACTION=="add|change", KERNEL=="md0", ATTR{queue/scheduler}="${DATA_SCHEDULER}", ATTR{queue/read_ahead_kb}="${DATA_READ_AHEAD_KB}", ATTR{queue/nr_requests}="${DATA_NR_REQUESTS}", ATTR{queue/rotational}="0"

# WAL RAID device tuning
ACTION=="add|change", KERNEL=="md1", ATTR{queue/scheduler}="${WAL_SCHEDULER}", ATTR{queue/read_ahead_kb}="${WAL_READ_AHEAD_KB}", ATTR{queue/nr_requests}="${WAL_NR_REQUESTS}", ATTR{queue/rotational}="0"
EOF

    udevadm control --reload-rules 2>/dev/null || true
    log_ok "Udev rules written to $rules_file"
}

verify() {
    log "=== VERIFICATION ==="

    local errors=0

    local data_md=$(basename "$DATA_RAID_DEVICE")
    local wal_md=$(basename "$WAL_RAID_DEVICE")

    local actual_read_ahead=$(get_sysfs_value "/sys/block/$data_md/queue/read_ahead_kb")
    assert_equal "$data_md read_ahead_kb" "$DATA_READ_AHEAD_KB" "$actual_read_ahead" || errors=$((errors + 1))

    actual_read_ahead=$(get_sysfs_value "/sys/block/$wal_md/queue/read_ahead_kb")
    assert_equal "$wal_md read_ahead_kb" "$WAL_READ_AHEAD_KB" "$actual_read_ahead" || errors=$((errors + 1))

    # stripe_cache_size only exists for RAID5/6, skip for RAID10
    if [ -f "/sys/block/$data_md/md/stripe_cache_size" ]; then
        local actual_stripe_cache=$(get_sysfs_value "/sys/block/$data_md/md/stripe_cache_size")
        assert_equal "$data_md stripe_cache_size" "$MD_STRIPE_CACHE_SIZE" "$actual_stripe_cache" || errors=$((errors + 1))
    else
        log_ok "$data_md stripe_cache_size: N/A (RAID10)"
    fi

    if [ -f "/sys/block/$wal_md/md/stripe_cache_size" ]; then
        local actual_stripe_cache=$(get_sysfs_value "/sys/block/$wal_md/md/stripe_cache_size")
        assert_equal "$wal_md stripe_cache_size" "$MD_STRIPE_CACHE_SIZE" "$actual_stripe_cache" || errors=$((errors + 1))
    else
        log_ok "$wal_md stripe_cache_size: N/A (RAID10)"
    fi

    if [ ! -f "/etc/udev/rules.d/99-disk-tuning.rules" ]; then
        log_fail "Udev rules file not found"
        errors=$((errors + 1))
    else
        log_ok "Udev rules file exists"
    fi

    if [ $errors -gt 0 ]; then
        log_fail "Verification failed with $errors errors"
        exit 1
    fi

    log_ok "All assertions passed"

    log "=== CURRENT SETTINGS ==="
    for dev in $data_md $wal_md; do
        echo "--- $dev ---"
        echo "  scheduler: $(cat /sys/block/$dev/queue/scheduler 2>/dev/null || echo 'N/A')"
        echo "  read_ahead_kb: $(cat /sys/block/$dev/queue/read_ahead_kb 2>/dev/null || echo 'N/A')"
        echo "  nr_requests: $(cat /sys/block/$dev/queue/nr_requests 2>/dev/null || echo 'N/A')"
        echo "  stripe_cache_size: $(cat /sys/block/$dev/md/stripe_cache_size 2>/dev/null || echo 'N/A')"
    done
}

main() {
    log "Starting disk tuning..."
    preflight
    apply_tuning
    create_udev_rules
    verify
    log "Disk tuning completed successfully"
}

main "$@"
