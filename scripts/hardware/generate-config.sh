#!/bin/bash
# =============================================================================
# Generate config.env for a hardware context
# =============================================================================
# Usage: ./generate-config.sh <instance_type> <data_disks> <wal_disks> [raid_level]
#
# Example:
#   ./generate-config.sh c8g.2xlarge 8 8 raid10
#   ./generate-config.sh r8g.4xlarge 16 8 raid10
#
# This creates: hardware/<context>/config.env with calculated values
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/_template/config.env.template"

# =============================================================================
# AWS Instance Specs Database
# Format: VCPU:RAM_GB:NET_GBPS:EBS_GBPS
# =============================================================================
get_instance_specs() {
    local instance_type="$1"
    case "$instance_type" in
        # C8g - Compute optimized (Graviton4)
        c8g.medium)   echo "1:2:12:10" ;;
        c8g.large)    echo "2:4:12:10" ;;
        c8g.xlarge)   echo "4:8:12:10" ;;
        c8g.2xlarge)  echo "8:16:15:10" ;;
        c8g.4xlarge)  echo "16:32:15:10" ;;
        c8g.8xlarge)  echo "32:64:15:10" ;;
        c8g.12xlarge) echo "48:96:22:15" ;;
        c8g.16xlarge) echo "64:128:30:20" ;;
        c8g.24xlarge) echo "96:192:40:30" ;;
        c8g.48xlarge) echo "192:384:50:40" ;;
        # R8g - Memory optimized (Graviton4)
        r8g.medium)   echo "1:8:12:10" ;;
        r8g.large)    echo "2:16:12:10" ;;
        r8g.xlarge)   echo "4:32:12:10" ;;
        r8g.2xlarge)  echo "8:64:15:10" ;;
        r8g.4xlarge)  echo "16:128:15:10" ;;
        r8g.8xlarge)  echo "32:256:15:10" ;;
        r8g.12xlarge) echo "48:384:22:15" ;;
        r8g.16xlarge) echo "64:512:30:20" ;;
        r8g.24xlarge) echo "96:768:40:30" ;;
        # M8g - General purpose (Graviton4)
        m8g.medium)   echo "1:4:12:10" ;;
        m8g.large)    echo "2:8:12:10" ;;
        m8g.xlarge)   echo "4:16:12:10" ;;
        m8g.2xlarge)  echo "8:32:15:10" ;;
        m8g.4xlarge)  echo "16:64:15:10" ;;
        m8g.8xlarge)  echo "32:128:15:10" ;;
        m8g.12xlarge) echo "48:192:22:15" ;;
        m8g.16xlarge) echo "64:256:30:20" ;;
        m8g.24xlarge) echo "96:384:40:30" ;;
        *) echo "" ;;
    esac
}

usage() {
    echo "Usage: $0 <instance_type> <data_disk_count> <wal_disk_count> [raid_level]"
    echo ""
    echo "Arguments:"
    echo "  instance_type    AWS instance type (e.g., c8g.2xlarge, r8g.4xlarge)"
    echo "  data_disk_count  Number of EBS disks for DATA volume (e.g., 8)"
    echo "  wal_disk_count   Number of EBS disks for WAL volume (e.g., 8)"
    echo "  raid_level       RAID level: raid0, raid1, raid10 (default: raid10)"
    echo ""
    echo "Supported instance types:"
    echo "  c8g.{medium,large,xlarge,2xlarge,4xlarge,8xlarge,12xlarge,16xlarge,24xlarge,48xlarge}"
    echo "  r8g.{medium,large,xlarge,2xlarge,4xlarge,8xlarge,12xlarge,16xlarge,24xlarge}"
    echo "  m8g.{medium,large,xlarge,2xlarge,4xlarge,8xlarge,12xlarge,16xlarge,24xlarge}"
    exit 1
}

# =============================================================================
# Parse Arguments
# =============================================================================
if [ $# -lt 3 ]; then
    usage
fi

INSTANCE_TYPE="$1"
DATA_DISK_COUNT="$2"
WAL_DISK_COUNT="$3"
RAID_LEVEL="${4:-raid10}"

# Get instance specs
SPECS=$(get_instance_specs "$INSTANCE_TYPE")
if [ -z "$SPECS" ]; then
    echo "ERROR: Unknown instance type: $INSTANCE_TYPE"
    echo ""
    usage
fi

# Parse instance specs
IFS=':' read -r VCPU RAM_GB NET_BW_GBPS EBS_BW_GBPS <<< "$SPECS"

echo "=== Hardware Context Generator ==="
echo "Instance: $INSTANCE_TYPE"
echo "  vCPU: $VCPU"
echo "  RAM: ${RAM_GB}GB"
echo "  Network: ${NET_BW_GBPS}Gbps"
echo "  EBS: ${EBS_BW_GBPS}Gbps"
echo "Data: ${DATA_DISK_COUNT} disks (${RAID_LEVEL})"
echo "WAL: ${WAL_DISK_COUNT} disks (${RAID_LEVEL})"
echo ""

# =============================================================================
# Calculate RAID parameters
# =============================================================================
case "$RAID_LEVEL" in
    raid0)
        DATA_STRIPE_WIDTH=$DATA_DISK_COUNT
        WAL_STRIPE_WIDTH=$WAL_DISK_COUNT
        RAID_NUM=0
        ;;
    raid1)
        DATA_STRIPE_WIDTH=1
        WAL_STRIPE_WIDTH=1
        RAID_NUM=1
        ;;
    raid10)
        DATA_STRIPE_WIDTH=$((DATA_DISK_COUNT / 2))
        WAL_STRIPE_WIDTH=$((WAL_DISK_COUNT / 2))
        RAID_NUM=10
        ;;
    *)
        echo "ERROR: Unknown RAID level: $RAID_LEVEL"
        exit 1
        ;;
esac

# =============================================================================
# Calculate PostgreSQL parameters
# =============================================================================

# Memory calculations
SHARED_BUFFERS_GB=$((RAM_GB / 4))                    # 25% RAM
EFFECTIVE_CACHE_GB=$((RAM_GB * 70 / 100))            # 70% RAM
MAINTENANCE_WORK_MEM_GB=$((RAM_GB / 16))             # 6.25% RAM, min 1GB
[ $MAINTENANCE_WORK_MEM_GB -lt 1 ] && MAINTENANCE_WORK_MEM_GB=1

# work_mem: RAM / max_connections / 4 (conservative for sort operations)
MAX_CONNECTIONS=300
WORK_MEM_MB=$((RAM_GB * 1024 / MAX_CONNECTIONS / 4))
[ $WORK_MEM_MB -lt 4 ] && WORK_MEM_MB=4
[ $WORK_MEM_MB -gt 256 ] && WORK_MEM_MB=256          # Cap at 256MB

# WAL sizing based on RAM
MAX_WAL_SIZE_GB=$((RAM_GB * 3))                      # 3x RAM
MIN_WAL_SIZE_GB=$((RAM_GB / 4))                      # 25% RAM
[ $MIN_WAL_SIZE_GB -lt 1 ] && MIN_WAL_SIZE_GB=1

# I/O concurrency based on disk count
EFFECTIVE_IO_CONCURRENCY=$((DATA_DISK_COUNT * 25))
[ $EFFECTIVE_IO_CONCURRENCY -gt 1000 ] && EFFECTIVE_IO_CONCURRENCY=1000

# Parallel workers based on vCPU
MAX_WORKER_PROCESSES=$VCPU
MAX_PARALLEL_WORKERS=$VCPU
MAX_PARALLEL_WORKERS_PER_GATHER=$((VCPU / 2))
[ $MAX_PARALLEL_WORKERS_PER_GATHER -lt 2 ] && MAX_PARALLEL_WORKERS_PER_GATHER=2
[ $MAX_PARALLEL_WORKERS_PER_GATHER -gt 8 ] && MAX_PARALLEL_WORKERS_PER_GATHER=8

# Autovacuum workers: 1 per 4 vCPU, min 2, max 8
AUTOVACUUM_MAX_WORKERS=$((VCPU / 4))
[ $AUTOVACUUM_MAX_WORKERS -lt 2 ] && AUTOVACUUM_MAX_WORKERS=2
[ $AUTOVACUUM_MAX_WORKERS -gt 8 ] && AUTOVACUUM_MAX_WORKERS=8

# Autovacuum cost limit: scale with disk capability
# Base 10000 for 8-disk RAID10, scale linearly
AUTOVACUUM_VACUUM_COST_LIMIT=$((10000 * DATA_DISK_COUNT / 8))
[ $AUTOVACUUM_VACUUM_COST_LIMIT -gt 20000 ] && AUTOVACUUM_VACUUM_COST_LIMIT=20000

# pgbench scale: ~150 bytes per account, aim for dataset = 1.2x RAM
PGBENCH_SCALE=$((RAM_GB * 1024 * 1024 * 1024 * 12 / 10 / 150 / 100000))
[ $PGBENCH_SCALE -lt 100 ] && PGBENCH_SCALE=100

# min_free_kbytes: 1% of RAM in KB
MIN_FREE_KBYTES=$((RAM_GB * 1024 * 1024 / 100))

# Disk sizes (default)
DATA_DISK_SIZE_GB=50
WAL_DISK_SIZE_GB=30

# =============================================================================
# Generate context name
# =============================================================================
HARDWARE_CONTEXT="${INSTANCE_TYPE}.${NET_BW_GBPS}.${EBS_BW_GBPS}.${DATA_DISK_COUNT}disk.${RAID_LEVEL}"
OUTPUT_DIR="${SCRIPT_DIR}/${HARDWARE_CONTEXT}"

echo "Context: $HARDWARE_CONTEXT"
echo "Output: $OUTPUT_DIR"
echo ""

# =============================================================================
# Create output directory and generate config
# =============================================================================
mkdir -p "$OUTPUT_DIR"

# Generate config.env from template
sed \
    -e "s/{{HARDWARE_CONTEXT}}/${HARDWARE_CONTEXT}/g" \
    -e "s/{{INSTANCE_TYPE}}/${INSTANCE_TYPE}/g" \
    -e "s/{{VCPU}}/${VCPU}/g" \
    -e "s/{{RAM_GB}}/${RAM_GB}/g" \
    -e "s/{{NET_BW_GBPS}}/${NET_BW_GBPS}/g" \
    -e "s/{{EBS_BW_GBPS}}/${EBS_BW_GBPS}/g" \
    -e "s/{{DISK_COUNT}}/${DATA_DISK_COUNT}/g" \
    -e "s/{{DISK_SIZE_GB}}/${DATA_DISK_SIZE_GB}/g" \
    -e "s/{{RAID_LEVEL}}/${RAID_LEVEL}/g" \
    -e "s/{{GENERATED_DATE}}/$(date -u +%Y-%m-%dT%H:%M:%SZ)/g" \
    -e "s/{{MIN_FREE_KBYTES}}/${MIN_FREE_KBYTES}/g" \
    -e "s/{{DATA_DISK_SIZE_GB}}/${DATA_DISK_SIZE_GB}/g" \
    -e "s/{{DATA_DISK_COUNT}}/${DATA_DISK_COUNT}/g" \
    -e "s/{{DATA_RAID_LEVEL}}/${RAID_NUM}/g" \
    -e "s/{{DATA_STRIPE_WIDTH}}/${DATA_STRIPE_WIDTH}/g" \
    -e "s/{{WAL_DISK_SIZE_GB}}/${WAL_DISK_SIZE_GB}/g" \
    -e "s/{{WAL_DISK_COUNT}}/${WAL_DISK_COUNT}/g" \
    -e "s/{{WAL_RAID_LEVEL}}/${RAID_NUM}/g" \
    -e "s/{{WAL_STRIPE_WIDTH}}/${WAL_STRIPE_WIDTH}/g" \
    -e "s/{{PG_MAX_CONNECTIONS}}/${MAX_CONNECTIONS}/g" \
    -e "s/{{PG_SHARED_BUFFERS}}/${SHARED_BUFFERS_GB}GB/g" \
    -e "s/{{PG_WORK_MEM}}/${WORK_MEM_MB}MB/g" \
    -e "s/{{PG_MAINTENANCE_WORK_MEM}}/${MAINTENANCE_WORK_MEM_GB}GB/g" \
    -e "s/{{PG_EFFECTIVE_CACHE_SIZE}}/${EFFECTIVE_CACHE_GB}GB/g" \
    -e "s/{{PG_EFFECTIVE_IO_CONCURRENCY}}/${EFFECTIVE_IO_CONCURRENCY}/g" \
    -e "s/{{PG_MAX_WAL_SIZE}}/${MAX_WAL_SIZE_GB}GB/g" \
    -e "s/{{PG_MIN_WAL_SIZE}}/${MIN_WAL_SIZE_GB}GB/g" \
    -e "s/{{PG_AUTOVACUUM_MAX_WORKERS}}/${AUTOVACUUM_MAX_WORKERS}/g" \
    -e "s/{{PG_AUTOVACUUM_VACUUM_COST_LIMIT}}/${AUTOVACUUM_VACUUM_COST_LIMIT}/g" \
    -e "s/{{PG_MAX_WORKER_PROCESSES}}/${MAX_WORKER_PROCESSES}/g" \
    -e "s/{{PG_MAX_PARALLEL_WORKERS_PER_GATHER}}/${MAX_PARALLEL_WORKERS_PER_GATHER}/g" \
    -e "s/{{PG_MAX_PARALLEL_WORKERS}}/${MAX_PARALLEL_WORKERS}/g" \
    -e "s/{{PGBENCH_SCALE}}/${PGBENCH_SCALE}/g" \
    "$TEMPLATE" > "${OUTPUT_DIR}/config.env"

echo "=== Generated config.env ==="
echo ""
echo "Key calculated values:"
echo "  shared_buffers:           ${SHARED_BUFFERS_GB}GB (25% of ${RAM_GB}GB)"
echo "  effective_cache_size:     ${EFFECTIVE_CACHE_GB}GB (70% of ${RAM_GB}GB)"
echo "  work_mem:                 ${WORK_MEM_MB}MB"
echo "  maintenance_work_mem:     ${MAINTENANCE_WORK_MEM_GB}GB"
echo "  max_wal_size:             ${MAX_WAL_SIZE_GB}GB"
echo "  effective_io_concurrency: ${EFFECTIVE_IO_CONCURRENCY}"
echo "  max_parallel_workers:     ${MAX_PARALLEL_WORKERS}"
echo "  autovacuum_max_workers:   ${AUTOVACUUM_MAX_WORKERS}"
echo "  pgbench_scale:            ${PGBENCH_SCALE}"
echo ""
echo "=== IMPORTANT ==="
echo "This config uses CALCULATED defaults. Experience-tuned values like:"
echo "  - bgwriter_delay=10ms"
echo "  - commit_delay=50"
echo "  - vm.dirty_background_ratio=1"
echo "are copied from benchmarked configs. Validate with actual benchmarks!"
echo ""
echo "Next steps:"
echo "  1. Review: cat ${OUTPUT_DIR}/config.env"
echo "  2. Benchmark: HARDWARE_CONTEXT=${HARDWARE_CONTEXT} ./bench.py"
echo "  3. Tune and commit the optimized config"
