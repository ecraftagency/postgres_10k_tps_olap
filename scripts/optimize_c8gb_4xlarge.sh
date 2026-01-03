#!/bin/bash
set -e

# ==============================================================================
# POSTGRESQL CONFIG SCRIPT: c8gb.4xlarge (16 vCPU / 32GB RAM)
# Target: 12K+ TPS, Stable Latency, Safe HugePages
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

echo ">>> Bắt đầu tính toán & cấu hình cho c8gb.4xlarge..."

# --- 1. HUGE PAGES SETUP (Calculated for 8GB Shared Buffers) ---
# Shared Buffers = 8GB = 8192MB
# Page Size = 2MB
# Need: 4096 pages.
# Buffer: +404 pages (Safety margin for PG overhead).
# Total: 4500 pages.

HUGE_PAGES_COUNT=4500
echo ">>> Cấu hình Huge Pages: $HUGE_PAGES_COUNT pages..."

cat > /etc/sysctl.d/99-postgres-hugepages.conf <<EOF
vm.nr_hugepages = $HUGE_PAGES_COUNT
EOF

# --- 2. KERNEL TUNING (32GB RAM Optimization) ---
echo ">>> Cấu hình Kernel (I/O Flush Strategy)..."

cat > /etc/sysctl.d/99-postgres-tuning.conf <<EOF
# --- MEMORY ---
vm.swappiness = 1

# --- I/O FLUSHING (Anti-Stall) ---
# Bắt đầu xả nền khi có 320MB (1%) bẩn
vm.dirty_background_ratio = 1
# Chặn ghi user process khi có 1.3GB (4%) bẩn
# Với băng thông 1.25GB/s, thời gian xả ~1s (An toàn).
vm.dirty_ratio = 4
vm.dirty_expire_centisecs = 200
vm.dirty_writeback_centisecs = 100

# --- NETWORK (Cho 10k connections) ---
net.core.somaxconn = 4096
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
EOF

# Apply config
sysctl -p /etc/sysctl.d/99-postgres-hugepages.conf
sysctl -p /etc/sysctl.d/99-postgres-tuning.conf

# Verify Huge Pages allocation
CURRENT_HP=$(grep HugePages_Total /proc/meminfo | awk '{print $2}')
echo ">>> Huge Pages hiện tại: $CURRENT_HP (Target: $HUGE_PAGES_COUNT)"
if [ "$CURRENT_HP" -lt "$HUGE_PAGES_COUNT" ]; then
    echo "WARNING: OS chưa cấp đủ Huge Pages. Postgres có thể fail start."
    echo "ACTION: Hãy thử 'echo 3 > /proc/sys/vm/drop_caches' để giải phóng RAM rồi chạy lại script."
fi

# --- 3. POSTGRESQL CONFIGURATION ---
PG_CONF="/etc/postgresql/16/main/postgresql.conf"

if [ ! -f "$PG_CONF" ]; then
    echo "ERROR: Không tìm thấy $PG_CONF. Kiểm tra đường dẫn."
    exit 1
fi

echo ">>> Backup config cũ..."
cp $PG_CONF $PG_CONF.bak.$(date +%s)

echo ">>> Ghi đè cấu hình tối ưu..."
cat >> $PG_CONF <<EOF

# ------------------------------------------------------------------------------
# OPTIMIZED CONFIG FOR c8gb.4xlarge (16 vCPU / 32GB RAM)
# ------------------------------------------------------------------------------

# --- CONNECTIONS ---
# 16 vCPU xử lý connection tốt hơn, tăng nhẹ limit.
max_connections = 400
reserved_connections = 10

# --- MEMORY & HUGE PAGES ---
shared_buffers = 8GB                    # 25% RAM
huge_pages = on                         # Crash nếu thiếu pages (An toàn hơn là chạy chậm)
temp_buffers = 16MB
work_mem = 48MB                         # Tăng nhẹ so với 16GB RAM
maintenance_work_mem = 1GB
effective_cache_size = 22GB             # Phần còn lại của RAM

# --- DISK I/O (RAID 10) ---
random_page_cost = 1.1
seq_page_cost = 1.0
effective_io_concurrency = 250          # 16 vCPU x Parallel IO capability

# --- WAL & RELIABILITY ---
synchronous_commit = on
wal_compression = lz4
wal_buffers = 64MB
max_wal_size = 48GB                     # Checkpoint thưa
min_wal_size = 2GB
checkpoint_timeout = 30min
checkpoint_completion_target = 0.9

# --- BACKGROUND WRITER (Aggressive) ---
bgwriter_delay = 10ms
bgwriter_lru_maxpages = 1000            # Giữ mức cao để dọn dẹp RAM 32GB
bgwriter_lru_multiplier = 10.0

# --- WAL WRITER ---
wal_writer_delay = 10ms

# --- GROUP COMMIT ---
# CPU mạnh hơn (16 core) nên xử lý batch nhanh hơn.
commit_delay = 30                       # 30us (Giữa mức 50us cũ và 20us của server khủng)
commit_siblings = 10

# --- PARALLEL QUERY (16 vCPU Power) ---
max_worker_processes = 16               # Full 16 cores
max_parallel_workers_per_gather = 4     # 1 query dùng tối đa 4 core
max_parallel_workers = 8

# --- AUTOVACUUM ---
autovacuum_max_workers = 6
autovacuum_vacuum_cost_limit = 3000

# --- LOGGING ---
log_min_duration_statement = 1000
log_checkpoints = on
EOF

echo ">>> Hoàn tất! Vui lòng:"
echo "1. sudo systemctl restart postgresql"
echo "2. Vào psql chạy: SHOW shared_buffers; (Phải là 8GB)"
