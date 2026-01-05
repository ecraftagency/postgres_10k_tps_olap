#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load-config.sh"

LOG_PREFIX="[01-os-tuning]"

log() { echo "$LOG_PREFIX $1"; }
log_ok() { echo "$LOG_PREFIX ✓ $1"; }
log_fail() { echo "$LOG_PREFIX ✗ $1"; }

assert_equal() {
    local name=$1 expected=$2 actual=$3
    if [ "$expected" != "$actual" ]; then
        log_fail "$name: expected=$expected actual=$actual"
        return 1
    fi
    log_ok "$name = $actual"
    return 0
}

assert_contains() {
    local name=$1 expected=$2 actual=$3
    if [[ "$actual" != *"$expected"* ]]; then
        log_fail "$name: expected contains '$expected', actual='$actual'"
        return 1
    fi
    log_ok "$name contains '$expected'"
    return 0
}

preflight() {
    log "=== PRE-FLIGHT CHECKS ==="

    if [ "$(id -u)" -ne 0 ]; then
        log_fail "Script phải chạy với root"
        exit 1
    fi
    log_ok "Running as root"

    if [ ! -d /etc/sysctl.d ]; then
        log_fail "/etc/sysctl.d không tồn tại"
        exit 1
    fi
    log_ok "/etc/sysctl.d exists"

    if [ ! -d /etc/security/limits.d ]; then
        log_fail "/etc/security/limits.d không tồn tại"
        exit 1
    fi
    log_ok "/etc/security/limits.d exists"

    if ! command -v systemctl &> /dev/null; then
        log_fail "systemctl không tồn tại"
        exit 1
    fi
    log_ok "systemctl available"
}

apply_sysctl() {
    log "=== APPLYING SYSCTL ==="

    local sysctl_file="/etc/sysctl.d/99-postgres-tuning.conf"

    cat > "$sysctl_file" << EOF
vm.swappiness = ${VM_SWAPPINESS}
vm.dirty_background_ratio = ${VM_DIRTY_BACKGROUND_RATIO}
vm.dirty_ratio = ${VM_DIRTY_RATIO}
vm.dirty_expire_centisecs = ${VM_DIRTY_EXPIRE_CENTISECS}
vm.dirty_writeback_centisecs = ${VM_DIRTY_WRITEBACK_CENTISECS}
vm.overcommit_memory = ${VM_OVERCOMMIT_MEMORY}
vm.overcommit_ratio = ${VM_OVERCOMMIT_RATIO}
vm.min_free_kbytes = ${VM_MIN_FREE_KBYTES}
vm.zone_reclaim_mode = ${VM_ZONE_RECLAIM_MODE}

fs.file-max = ${FS_FILE_MAX}
fs.aio-max-nr = ${FS_AIO_MAX_NR}

net.core.somaxconn = ${NET_CORE_SOMAXCONN}
net.core.netdev_max_backlog = ${NET_CORE_NETDEV_MAX_BACKLOG}
net.core.rmem_default = ${NET_CORE_RMEM_DEFAULT}
net.core.rmem_max = ${NET_CORE_RMEM_MAX}
net.core.wmem_default = ${NET_CORE_WMEM_DEFAULT}
net.core.wmem_max = ${NET_CORE_WMEM_MAX}
net.ipv4.tcp_rmem = ${NET_IPV4_TCP_RMEM}
net.ipv4.tcp_wmem = ${NET_IPV4_TCP_WMEM}
net.ipv4.tcp_max_syn_backlog = ${NET_IPV4_TCP_MAX_SYN_BACKLOG}
net.ipv4.tcp_tw_reuse = ${NET_IPV4_TCP_TW_REUSE}
net.ipv4.tcp_fin_timeout = ${NET_IPV4_TCP_FIN_TIMEOUT}

kernel.sched_autogroup_enabled = ${KERNEL_SCHED_AUTOGROUP_ENABLED}
kernel.numa_balancing = ${KERNEL_NUMA_BALANCING}
kernel.sem = ${KERNEL_SEM}
EOF

    log_ok "Written $sysctl_file"

    sysctl --system > /dev/null 2>&1
    log_ok "sysctl --system applied"
}

apply_limits() {
    log "=== APPLYING LIMITS ==="

    local limits_file="/etc/security/limits.d/99-postgres.conf"

    cat > "$limits_file" << EOF
* soft nofile ${ULIMIT_NOFILE}
* hard nofile ${ULIMIT_NOFILE}
* soft nproc ${ULIMIT_NPROC}
* hard nproc ${ULIMIT_NPROC}
root soft nofile ${ULIMIT_NOFILE}
root hard nofile ${ULIMIT_NOFILE}
EOF

    log_ok "Written $limits_file"
}

apply_thp() {
    log "=== DISABLING THP ==="

    local thp_service="/etc/systemd/system/disable-thp.service"

    cat > "$thp_service" << 'EOF'
[Unit]
Description=Disable Transparent Huge Pages
DefaultDependencies=no
After=sysinit.target local-fs.target
Before=basic.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/defrag'

[Install]
WantedBy=basic.target
EOF

    systemctl daemon-reload
    systemctl enable disable-thp.service > /dev/null 2>&1
    systemctl start disable-thp.service > /dev/null 2>&1 || true

    log_ok "THP service configured"
}

apply_scheduler() {
    log "=== SETTING I/O SCHEDULER ==="

    local count=0
    for disk in /sys/block/nvme* /sys/block/sd*; do
        [ -d "$disk" ] || continue
        local devname=$(basename "$disk")
        if echo none > "$disk/queue/scheduler" 2>/dev/null; then
            count=$((count + 1))
        fi
    done

    log_ok "Set scheduler=none for $count devices"
}

verify() {
    log "=== VERIFICATION ==="

    local errors=0

    assert_equal "vm.swappiness" "$VM_SWAPPINESS" "$(cat /proc/sys/vm/swappiness)" || errors=$((errors + 1))
    assert_equal "vm.dirty_background_ratio" "$VM_DIRTY_BACKGROUND_RATIO" "$(cat /proc/sys/vm/dirty_background_ratio)" || errors=$((errors + 1))
    assert_equal "vm.dirty_ratio" "$VM_DIRTY_RATIO" "$(cat /proc/sys/vm/dirty_ratio)" || errors=$((errors + 1))
    assert_equal "vm.overcommit_memory" "$VM_OVERCOMMIT_MEMORY" "$(cat /proc/sys/vm/overcommit_memory)" || errors=$((errors + 1))
    assert_equal "fs.file-max" "$FS_FILE_MAX" "$(cat /proc/sys/fs/file-max)" || errors=$((errors + 1))
    assert_equal "net.core.somaxconn" "$NET_CORE_SOMAXCONN" "$(cat /proc/sys/net/core/somaxconn)" || errors=$((errors + 1))

    if [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
        local thp_status=$(cat /sys/kernel/mm/transparent_hugepage/enabled)
        assert_contains "THP" "never" "$thp_status" || errors=$((errors + 1))
    fi

    if [ $errors -gt 0 ]; then
        log_fail "Verification failed with $errors errors"
        exit 1
    fi

    log_ok "All assertions passed"
}

main() {
    log "Starting OS tuning..."
    preflight
    apply_sysctl
    apply_limits
    apply_thp
    apply_scheduler
    verify
    log "OS tuning completed successfully"
}

main "$@"
