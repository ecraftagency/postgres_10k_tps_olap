#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.env"

LOG_PREFIX="[02-raid-setup]"

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

assert_ge() {
    local name=$1 expected=$2 actual=$3
    if [ "$actual" -lt "$expected" ]; then
        log_fail "$name: expected >= $expected, actual=$actual"
        return 1
    fi
    log_ok "$name = $actual (>= $expected)"
    return 0
}

get_disks_by_size() {
    local size_gb=$1
    lsblk -b -d -n -o NAME,SIZE | awk -v size="$((size_gb * 1073741824))" '$2 == size {print "/dev/"$1}'
}

get_raid_chunk_kb() {
    local device=$1
    mdadm --detail "$device" 2>/dev/null | grep "Chunk Size" | awk '{print $4}' | sed 's/K//'
}

get_xfs_sunit() {
    local mount=$1
    xfs_info "$mount" 2>/dev/null | grep "^data" | sed -n 's/.*sunit=\([0-9]*\).*/\1/p'
}

chunk_to_kb() {
    local chunk=$1
    echo "$chunk" | sed 's/K$//' | sed 's/M$/*1024/' | bc
}

preflight() {
    log "=== PRE-FLIGHT CHECKS ==="

    if [ "$(id -u)" -ne 0 ]; then
        log_fail "Script phải chạy với root"
        exit 1
    fi
    log_ok "Running as root"

    for cmd in mdadm mkfs.xfs xfs_info lsblk blkid; do
        if ! command -v $cmd &> /dev/null; then
            log "Installing missing packages..."
            apt-get update && apt-get install -y mdadm xfsprogs
            break
        fi
    done
    log_ok "Required commands available"

    local data_disks=$(get_disks_by_size "$DATA_DISK_SIZE_GB" | wc -l)
    local wal_disks=$(get_disks_by_size "$WAL_DISK_SIZE_GB" | wc -l)

    local max_wait=120
    local waited=0
    while [ "$data_disks" -lt "$DATA_DISK_COUNT" ] || [ "$wal_disks" -lt "$WAL_DISK_COUNT" ]; do
        log "Waiting for disks... DATA=$data_disks/$DATA_DISK_COUNT, WAL=$wal_disks/$WAL_DISK_COUNT"
        sleep 5
        waited=$((waited + 5))
        if [ "$waited" -ge "$max_wait" ]; then
            log_fail "Timeout waiting for disks"
            exit 1
        fi
        data_disks=$(get_disks_by_size "$DATA_DISK_SIZE_GB" | wc -l)
        wal_disks=$(get_disks_by_size "$WAL_DISK_SIZE_GB" | wc -l)
    done

    log_ok "DATA disks: $data_disks available"
    log_ok "WAL disks: $wal_disks available"
}

check_raid_state() {
    local device=$1
    local expected_chunk_kb=$2
    local disk_count=$3

    if [ ! -e "$device" ]; then
        echo "missing"
        return
    fi

    local current_chunk=$(get_raid_chunk_kb "$device")
    if [ "$current_chunk" != "$expected_chunk_kb" ]; then
        echo "wrong_chunk:$current_chunk"
        return
    fi

    local current_disks=$(mdadm --detail "$device" 2>/dev/null | grep "Raid Devices" | awk '{print $4}')
    if [ "$current_disks" != "$disk_count" ]; then
        echo "wrong_disks:$current_disks"
        return
    fi

    echo "ok"
}

create_raid() {
    local device=$1
    local level=$2
    local chunk=$3
    local disk_count=$4
    shift 4
    local disks="$*"

    local chunk_kb=$(chunk_to_kb "$chunk")
    local state=$(check_raid_state "$device" "$chunk_kb" "$disk_count")

    case "$state" in
        ok)
            log_ok "$device already configured correctly"
            return 0
            ;;
        missing)
            log "Creating $device..."
            ;;
        wrong_chunk:*)
            local current=$(echo "$state" | cut -d: -f2)
            log_warn "$device has wrong chunk size: ${current}K (expected: $chunk)"
            log "Recreating $device..."
            mdadm --stop "$device" 2>/dev/null || true
            for disk in $disks; do
                mdadm --zero-superblock "$disk" 2>/dev/null || true
            done
            ;;
        wrong_disks:*)
            local current=$(echo "$state" | cut -d: -f2)
            log_warn "$device has wrong disk count: $current (expected: $disk_count)"
            log_fail "Cannot fix disk count mismatch automatically"
            exit 1
            ;;
    esac

    mdadm --create "$device" \
        --level="$level" \
        --raid-devices="$disk_count" \
        --chunk="$chunk" \
        --bitmap=none \
        --run \
        --force \
        $disks

    log_ok "$device created with chunk=$chunk"
}

check_xfs_state() {
    local device=$1
    local mount=$2
    local expected_sunit=$3

    if ! blkid "$device" 2>/dev/null | grep -q 'TYPE="xfs"'; then
        echo "not_formatted"
        return
    fi

    if ! mountpoint -q "$mount" 2>/dev/null; then
        echo "not_mounted"
        return
    fi

    local current_sunit=$(get_xfs_sunit "$mount")
    if [ -n "$current_sunit" ] && [ "$current_sunit" != "$expected_sunit" ]; then
        echo "wrong_sunit:$current_sunit"
        return
    fi

    echo "ok"
}

format_xfs() {
    local device=$1
    local mount=$2
    local stripe_unit=$3
    local stripe_width=$4
    local agcount=$5
    local mount_opts=$6

    local sunit_blocks=$(($(echo "$stripe_unit" | sed 's/k//') * 1024 / 512))
    local state=$(check_xfs_state "$device" "$mount" "$sunit_blocks")

    case "$state" in
        ok)
            log_ok "$device XFS already configured correctly"
            return 0
            ;;
        not_formatted)
            log "Formatting $device with XFS..."
            ;;
        not_mounted)
            log "Mounting $device..."
            mkdir -p "$mount"
            mount -o "$mount_opts" "$device" "$mount" && log_ok "Mounted $device" && return 0
            log_warn "Mount failed, reformatting..."
            ;;
        wrong_sunit:*)
            local current=$(echo "$state" | cut -d: -f2)
            log_warn "$device has wrong sunit: $current (expected: $sunit_blocks)"
            log_warn "XFS cannot be reformatted while mounted. Manual intervention required."
            log_fail "Unmount $mount and re-run script to reformat"
            exit 1
            ;;
    esac

    mkfs.xfs -f \
        -d su="$stripe_unit",sw="$stripe_width",agcount="$agcount" \
        -l su="$XFS_LOG_STRIPE_UNIT" \
        "$device"

    log_ok "$device formatted with XFS (su=$stripe_unit, sw=$stripe_width)"

    mkdir -p "$mount"

    if ! grep -q "$mount" /etc/fstab; then
        echo "$device $mount xfs $mount_opts 0 0" >> /etc/fstab
        log_ok "Added $mount to /etc/fstab"
    fi

    mount "$mount"
    log_ok "Mounted $mount"
}

save_mdadm_config() {
    log "=== SAVING MDADM CONFIG ==="

    local mdadm_conf="/etc/mdadm/mdadm.conf"
    local temp_conf=$(mktemp)

    if [ -f "$mdadm_conf" ]; then
        grep -v "^ARRAY" "$mdadm_conf" > "$temp_conf" || true
    fi

    mdadm --detail --scan >> "$temp_conf"
    mv "$temp_conf" "$mdadm_conf"

    update-initramfs -u > /dev/null 2>&1
    log_ok "mdadm.conf updated"
}

verify() {
    log "=== VERIFICATION ==="

    local errors=0

    if [ ! -e "$DATA_RAID_DEVICE" ]; then
        log_fail "$DATA_RAID_DEVICE does not exist"
        errors=$((errors + 1))
    else
        local data_chunk=$(get_raid_chunk_kb "$DATA_RAID_DEVICE")
        local expected_chunk=$(chunk_to_kb "$DATA_RAID_CHUNK")
        assert_equal "DATA RAID chunk" "$expected_chunk" "$data_chunk" || errors=$((errors + 1))
    fi

    if [ ! -e "$WAL_RAID_DEVICE" ]; then
        log_fail "$WAL_RAID_DEVICE does not exist"
        errors=$((errors + 1))
    else
        local wal_chunk=$(get_raid_chunk_kb "$WAL_RAID_DEVICE")
        local expected_chunk=$(chunk_to_kb "$WAL_RAID_CHUNK")
        assert_equal "WAL RAID chunk" "$expected_chunk" "$wal_chunk" || errors=$((errors + 1))
    fi

    if ! mountpoint -q "$DATA_MOUNT"; then
        log_fail "$DATA_MOUNT not mounted"
        errors=$((errors + 1))
    else
        log_ok "$DATA_MOUNT mounted"
    fi

    if ! mountpoint -q "$WAL_MOUNT"; then
        log_fail "$WAL_MOUNT not mounted"
        errors=$((errors + 1))
    else
        log_ok "$WAL_MOUNT mounted"
    fi

    local data_size_gb=$(df -BG "$DATA_MOUNT" 2>/dev/null | tail -1 | awk '{print $2}' | sed 's/G//')
    local expected_data_gb=$((DATA_DISK_SIZE_GB * DATA_DISK_COUNT / 2))
    if [ -n "$data_size_gb" ]; then
        assert_ge "DATA size (GB)" "$((expected_data_gb - 10))" "$data_size_gb" || errors=$((errors + 1))
    fi

    if [ $errors -gt 0 ]; then
        log_fail "Verification failed with $errors errors"
        exit 1
    fi

    log_ok "All assertions passed"

    log "=== RAID STATUS ==="
    cat /proc/mdstat
}

main() {
    log "Starting RAID setup..."

    preflight

    log "=== CREATING RAID ARRAYS ==="
    DATA_DISKS=$(get_disks_by_size "$DATA_DISK_SIZE_GB" | tr '\n' ' ')
    WAL_DISKS=$(get_disks_by_size "$WAL_DISK_SIZE_GB" | tr '\n' ' ')

    create_raid "$DATA_RAID_DEVICE" "$DATA_RAID_LEVEL" "$DATA_RAID_CHUNK" "$DATA_DISK_COUNT" $DATA_DISKS
    create_raid "$WAL_RAID_DEVICE" "$WAL_RAID_LEVEL" "$WAL_RAID_CHUNK" "$WAL_DISK_COUNT" $WAL_DISKS

    save_mdadm_config

    log "=== FORMATTING XFS ==="
    format_xfs "$DATA_RAID_DEVICE" "$DATA_MOUNT" "$XFS_DATA_SUNIT" "$DATA_STRIPE_WIDTH" "$XFS_DATA_AGCOUNT" "$XFS_MOUNT_OPTS_DATA"
    format_xfs "$WAL_RAID_DEVICE" "$WAL_MOUNT" "$XFS_WAL_SUNIT" "$WAL_STRIPE_WIDTH" "$XFS_WAL_AGCOUNT" "$XFS_MOUNT_OPTS_WAL"

    verify

    log "RAID setup completed successfully"
}

main "$@"
