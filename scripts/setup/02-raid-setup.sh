#!/bin/bash
# =============================================================================
# 02-raid-setup.sh - RAID0 Setup (Testing - Max Performance)
# =============================================================================
# RAID0 = striping only, no redundancy (OK for testing)
# DATA: 4x 50GB -> /dev/md0 -> /data
# WAL:  4x 30GB -> /dev/md1 -> /wal
# =============================================================================

set -e

echo "=== RAID0 Setup (Idempotent) ==="

# 1. Check if RAID is already correctly setup
if [ -b /dev/md0 ] && [ -b /dev/md1 ] && mountpoint -q /data && mountpoint -q /wal; then
    echo "RAID arrays (md0, md1) are already active and mounted. Skipping re-creation."
    exit 0
fi

echo "Forcing RAID cleanup..."

# Terminate processes holding the mounts
fuser -k /data /wal 2>/dev/null || true

# Stop potentially holding services
systemctl stop postgresql 2>/dev/null || true
systemctl stop postgresql-bench 2>/dev/null || true

# Unmount if mounted (forced)
umount -f /data 2>/dev/null || true
umount -f /wal 2>/dev/null || true

# Stop any existing arrays
mdadm --stop /dev/md0 2>/dev/null || true
mdadm --stop /dev/md1 2>/dev/null || true
mdadm --stop --scan 2>/dev/null || true

# Detect all NVMe devices (excluding root)
ALL_NVME=$(lsblk -d -n -o NAME | grep nvme | grep -v nvme0 | awk '{print "/dev/"$1}')

# Wipe metadata to prevent auto-reassembly
echo "Wiping RAID metadata on components: $ALL_NVME"
for dev in $ALL_NVME; do
    mdadm --zero-superblock "$dev" 2>/dev/null || true
    wipefs -a "$dev" 2>/dev/null || true
done

# Detect NVMe devices by size
echo "Redetecting volumes..."
lsblk -b -d -n -o NAME,SIZE | tee /tmp/lsblk_debug.txt

DATA_DEVS=$(lsblk -b -d -n -o NAME,SIZE | awk '$2 >= 53000000000 && $2 < 55000000000 {print "/dev/"$1}' | head -4 | tr '\n' ' ')
WAL_DEVS=$(lsblk -b -d -n -o NAME,SIZE | awk '$2 >= 32000000000 && $2 < 34000000000 {print "/dev/"$1}' | head -4 | tr '\n' ' ')

echo "Detected DATA_DEVS: [$DATA_DEVS]"
echo "Detected WAL_DEVS: [$WAL_DEVS]"

if [ -z "$DATA_DEVS" ] || [ -z "$WAL_DEVS" ]; then
    echo "ERROR: Could not detect correct volumes."
    echo "Check /tmp/lsblk_debug.txt for output of lsblk."
    exit 1
fi

# Create RAID0 arrays
echo "Creating RAID0 arrays..."
mdadm --create --verbose /dev/md0 --level=0 --raid-devices=4 $DATA_DEVS --run
mdadm --create --verbose /dev/md1 --level=0 --raid-devices=4 $WAL_DEVS --run

# Format XFS
echo "Formatting XFS..."
mkfs.xfs -f /dev/md0
mkfs.xfs -f /dev/md1

# Create mount points
mkdir -p /data /wal

# Mount
mount -o noatime,nodiratime /dev/md0 /data
mount -o noatime,nodiratime /dev/md1 /wal

# Add to fstab (idempotent)
grep -q '/dev/md0' /etc/fstab || echo '/dev/md0 /data xfs noatime,nodiratime 0 0' >> /etc/fstab
grep -q '/dev/md1' /etc/fstab || echo '/dev/md1 /wal xfs noatime,nodiratime 0 0' >> /etc/fstab

# Verify
echo ""
echo "=== Verification ==="
cat /proc/mdstat
df -h /data /wal

echo ""
echo "=== Done! Next: sudo ./03-disk-tuning.sh ==="
