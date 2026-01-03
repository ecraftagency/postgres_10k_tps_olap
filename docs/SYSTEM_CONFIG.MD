# System Configuration Guide

Hướng dẫn cấu hình OS và Disk I/O cho PostgreSQL heavy-write OLTP trên AWS EBS gp3 RAID10.

**Impact: +41% TPS** khi tune OS đúng cách (từ ~7K lên ~10K TPS)

---

## 1. Tổng quan Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                       STORAGE STACK                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  PostgreSQL                                                    │ │
│  │  Block: 8KB pages                                              │ │
│  │  Pattern: Random (DATA) + Sequential (WAL)                    │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              │                                      │
│                              ▼                                      │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Linux Kernel                                                  │ │
│  │  Page Cache: vm.dirty_* controls flushing                     │ │
│  │  I/O Scheduler: none (NVMe has hardware queue)                │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              │                                      │
│                              ▼                                      │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  XFS Filesystem                                                │ │
│  │  Block: 4KB, Aligned to RAID stripe                           │ │
│  │  Mount: noatime, nodiratime, logbufs=8                        │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              │                                      │
│                              ▼                                      │
│  ┌─────────────────────────┐    ┌─────────────────────────┐        │
│  │  RAID10 md0 (DATA)      │    │  RAID10 md1 (WAL)       │        │
│  │  Chunk: 64KB            │    │  Chunk: 256KB           │        │
│  │  8× gp3 → 4 stripes     │    │  8× gp3 → 4 stripes     │        │
│  └─────────────────────────┘    └─────────────────────────┘        │
│                              │                                      │
│                              ▼                                      │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  EBS gp3 (Network Storage)                                    │ │
│  │  Latency: 1.5-2.5ms (measured: 0.6ms random read)            │ │
│  │  IOPS: 3000/disk, Throughput: 125 MB/s/disk                  │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. OS Tuning - Memory (vm.*)

### 2.1 Vấn đề: I/O Cliff (Vách đá I/O)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    THE "I/O CLIFF" PROBLEM                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   Với DEFAULT Linux config:                                         │
│   vm.dirty_background_ratio = 10  (flush khi 10% RAM bẩn = 1.6GB)  │
│   vm.dirty_expire_centisecs = 3000 (data nằm RAM 30 giây)          │
│                                                                     │
│   TPS                                                               │
│    ▲                                                                │
│ 17K│  ████████                                                      │
│    │  ████████                                                      │
│ 12K│  ████████ ████                                                 │
│    │  ████████ ████                                                 │
│  7K│  ████████ ████ ████████████████████████████████████           │
│    │  ████████ ████ ████████████████████████████████████           │
│  0 └──────────────────────────────────────────────────────► Time   │
│       0-20s    20s+                                                 │
│       (RAM)    (DISK FLUSH - I/O CLIFF!)                           │
│                                                                     │
│   Timeline:                                                         │
│   • 0-20s: Writes → RAM Page Cache → TPS 17K (fast!)               │
│   • 20s: RAM dirty đạt 1.6GB (10%)                                 │
│   • 20s+: OS flush 1.6GB cùng lúc → Disk nghẽn → TPS 7K            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 Giải pháp: Aggressive Flushing

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AGGRESSIVE FLUSHING STRATEGY                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   Nguyên tắc: "Xả sớm, xả nhỏ, xả liên tục"                        │
│                                                                     │
│   DEFAULT                          TUNED                            │
│   ───────────────────────          ──────────────────────           │
│   dirty_background = 10%           dirty_background = 1%            │
│   (1.6GB threshold)                (150MB threshold)                │
│                                                                     │
│   dirty_expire = 30s               dirty_expire = 2s                │
│   (data nằm lâu)                   (data fresh)                     │
│                                                                     │
│   dirty_writeback = 5s             dirty_writeback = 1s             │
│   (quét chậm)                      (quét liên tục)                  │
│                                                                     │
│   Kết quả:                                                          │
│   ┌─────────────────────────────────────────────────────────────┐  │
│   │                                                             │  │
│   │  TPS: 7K ──────────────────────────────► 10K (+41%)        │  │
│   │                                                             │  │
│   │  I/O Cliff: Severe ─────────────────────► Mild             │  │
│   │                                                             │  │
│   └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.3 Memory Parameters

| Parameter | Default | Tuned | Impact |
|-----------|---------|-------|--------|
| `vm.swappiness` | 60 | **1** | Cấm swap - OOM tốt hơn swap trên EBS |
| `vm.dirty_background_ratio` | 10 | **1** | Flush khi 1% RAM bẩn (~150MB) |
| `vm.dirty_ratio` | 20 | **4** | Block writes khi 4% (~600MB) |
| `vm.dirty_expire_centisecs` | 3000 | **200** | Data max 2s trong RAM |
| `vm.dirty_writeback_centisecs` | 500 | **100** | Flush thread mỗi 1s |
| `vm.overcommit_memory` | 0 | **2** | Strict overcommit |
| `vm.overcommit_ratio` | 50 | **80** | 80% RAM limit |
| `vm.min_free_kbytes` | 67584 | **102400** | 100MB reserved |

### 2.4 Tại sao mỗi giá trị?

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PARAMETER REASONING                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  vm.swappiness = 1                                                  │
│  ───────────────────────────────────────────────────────────────   │
│  EBS latency: ~1.8ms (network storage)                             │
│  RAM latency: ~100ns                                                │
│  Ratio: 18,000x slower!                                            │
│  → Database thà chết (OOM) còn hơn sống dặt dẹo trên swap          │
│                                                                     │
│  vm.dirty_background_ratio = 1                                      │
│  ───────────────────────────────────────────────────────────────   │
│  16GB RAM × 1% = 160MB                                             │
│  → Bắt đầu flush ngay khi có 160MB dirty                           │
│  → Không để tích tụ thành 1.6GB như default                        │
│                                                                     │
│  vm.dirty_expire_centisecs = 200                                    │
│  ───────────────────────────────────────────────────────────────   │
│  200 centisecs = 2 seconds                                         │
│  → Data không được nằm trong RAM quá 2 giây                        │
│  → Giảm data loss nếu crash                                        │
│  → Ép flush liên tục                                               │
│                                                                     │
│  vm.dirty_writeback_centisecs = 100                                 │
│  ───────────────────────────────────────────────────────────────   │
│  100 centisecs = 1 second                                          │
│  → Flush thread (pdflush) thức dậy mỗi giây                        │
│  → Quét và xả dirty pages liên tục                                 │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. OS Tuning - Huge Pages & THP

### 3.1 Disable Transparent Huge Pages (THP)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    THP PROBLEM                                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  THP (Transparent Huge Pages) = Linux tự động dùng 2MB pages       │
│                                                                     │
│  Vấn đề cho Database:                                               │
│  1. THP defrag: Kernel dừng mọi thứ để gom memory → latency spike  │
│  2. Memory bloat: 2MB granularity thay vì 4KB                      │
│  3. Unpredictable: Không biết khi nào defrag xảy ra               │
│                                                                     │
│  PostgreSQL benchmark với THP enabled:                              │
│    Latency p99: 50ms → 200ms (spike 4x!)                           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

| Parameter | Value | Method |
|-----------|-------|--------|
| THP enabled | **never** | `echo never > /sys/kernel/mm/transparent_hugepage/enabled` |
| THP defrag | **never** | `echo never > /sys/kernel/mm/transparent_hugepage/defrag` |

---

## 4. OS Tuning - File Descriptors & Limits

### 4.1 System Limits

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `fs.file-max` | **2097152** | Max file handles system-wide |
| `fs.aio-max-nr` | **1048576** | Max async I/O requests |

### 4.2 User Limits (/etc/security/limits.conf)

```bash
# PostgreSQL user limits
postgres soft nofile 65535
postgres hard nofile 65535
postgres soft nproc 65535
postgres hard nproc 65535
```

---

## 5. OS Tuning - Network/TCP

### 5.1 TCP Parameters

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `net.core.somaxconn` | **4096** | Listen queue for connections |
| `net.core.rmem_max` | **16777216** | Max receive buffer 16MB |
| `net.core.wmem_max` | **16777216** | Max send buffer 16MB |
| `net.ipv4.tcp_tw_reuse` | **1** | Reuse TIME_WAIT sockets |
| `net.ipv4.tcp_fin_timeout` | **15** | Reduce FIN_WAIT from 60s |

### 5.2 Tại sao cần tune TCP?

```
PostgreSQL với 300 connections + Connection Pooling:
  • Nhiều short-lived connections
  • TIME_WAIT sockets tích tụ
  • tcp_tw_reuse = 1: Reuse sockets nhanh
  • tcp_fin_timeout = 15: Giải phóng sockets sớm
```

---

## 6. OS Tuning - Scheduler

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `kernel.sched_autogroup_enabled` | **0** | Disable auto-grouping |
| `kernel.numa_balancing` | **0** | Disable NUMA auto-balancing |

**Tại sao tắt?**
- PostgreSQL tự quản lý processes
- Auto-grouping gây unpredictable scheduling
- NUMA balancing gây latency spikes khi migrate pages

---

## 7. Disk I/O - RAID Configuration

### 7.1 RAID10 Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                       RAID10 LAYOUT                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  DATA Volume (/dev/md0)                 WAL Volume (/dev/md1)       │
│  ─────────────────────────              ─────────────────────       │
│                                                                     │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐      ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐│
│  │nvme2│ │nvme3│ │nvme5│ │nvme8│      │nvme1│ │nvme4│ │nvme6│ │nvme7││
│  │ A1  │ │ B1  │ │ A2  │ │ B2  │      │ A1  │ │ B1  │ │ A2  │ │ B2  ││
│  └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘      └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘│
│     │      │       │      │              │      │       │      │    │
│     └──────┘       └──────┘              └──────┘       └──────┘    │
│     Mirror 1       Mirror 2              Mirror 1       Mirror 2    │
│     (Stripe 1)     (Stripe 2)            (Stripe 1)     (Stripe 2)  │
│                                                                     │
│  Chunk: 64KB (random I/O)               Chunk: 256KB (sequential)   │
│  Usable: 200GB (50% of 400GB)          Usable: 120GB (50% of 240GB)│
│  Read IOPS: 8 × 3K = 24K               Read IOPS: 8 × 3K = 24K     │
│  Write IOPS: 4 × 3K = 12K              Write IOPS: 4 × 3K = 12K    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 7.2 Chunk Size Strategy

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CHUNK SIZE SELECTION                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  DATA Volume: Chunk = 64KB                                          │
│  ───────────────────────────────────────────────────────────────   │
│                                                                     │
│  PostgreSQL writes 8KB pages randomly                               │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Chunk (64KB)                                                 │  │
│  │  ┌────┬────┬────┬────┬────┬────┬────┬────┐                   │  │
│  │  │8KB │8KB │8KB │8KB │8KB │8KB │8KB │8KB │                   │  │
│  │  │ ██ │    │    │    │    │    │    │    │  ← 8KB write      │  │
│  │  └────┴────┴────┴────┴────┴────┴────┴────┘    fits in 1 chunk│  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  8KB << 64KB → Mỗi write nằm gọn trong 1 chunk → No split I/O     │
│                                                                     │
│  WAL Volume: Chunk = 256KB                                          │
│  ───────────────────────────────────────────────────────────────   │
│                                                                     │
│  WAL writes sequential, 8KB-64KB at a time                         │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Chunk (256KB)                                                │  │
│  │  ┌────────────────────────────────────────────────────────┐  │  │
│  │  │████████████████████████████████████████████████████████│  │  │
│  │  │  Sequential writes fill chunk → Max throughput         │  │  │
│  │  └────────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  Chunk lớn = Ít seeks = Throughput cao cho sequential I/O          │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 7.3 RAID Configuration Summary

| Aspect | DATA Volume | WAL Volume | Reasoning |
|--------|-------------|------------|-----------|
| RAID Level | **RAID10** | **RAID10** | Balance performance + redundancy |
| Chunk Size | **64KB** | **256KB** | Random small vs Sequential large |
| Stripe Width | 4 disks | 4 disks | Half of 8 disks (mirror) |
| Stripe Size | 256KB | 1MB | chunk × stripe_width |
| Usable Capacity | 200GB | 120GB | 50% of raw (mirror overhead) |

---

## 8. Disk I/O - XFS Configuration

### 8.1 XFS Alignment Principle

```
┌─────────────────────────────────────────────────────────────────────┐
│                    XFS STRIPE ALIGNMENT                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Nguyên tắc:                                                        │
│    XFS sunit = RAID chunk size                                      │
│    XFS swidth = Number of data disks                               │
│                                                                     │
│  DATA Volume:                                                       │
│    sunit = 64KB (RAID chunk)                                       │
│    swidth = 4 (4 data disks in RAID10)                             │
│                                                                     │
│  WAL Volume:                                                        │
│    sunit = 256KB (RAID chunk)                                      │
│    swidth = 4 (4 data disks in RAID10)                             │
│                                                                     │
│  Log stripe unit = 1 block:                                         │
│    PostgreSQL fsync rất thường xuyên                               │
│    Log sunit lớn → padding → waste I/O                             │
│    1 block = no padding = lowest latency                           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 8.2 XFS Format Options

| Volume | sunit | swidth | log sunit | agcount |
|--------|-------|--------|-----------|---------|
| DATA | 64k | 4 | 1b | 16 |
| WAL | 256k | 4 | 1b | 8 |

### 8.3 XFS Mount Options

```bash
# DATA Volume (Random I/O)
/dev/md0 /data xfs defaults,noatime,nodiratime,logbufs=8,logbsize=256k,allocsize=64m,inode64 0 0

# WAL Volume (Sequential I/O)
/dev/md1 /wal xfs defaults,noatime,nodiratime,logbufs=8,logbsize=256k,inode64 0 0
```

| Option | Purpose |
|--------|---------|
| `noatime` | Không update access time → giảm writes |
| `nodiratime` | Không update directory access time |
| `logbufs=8` | 8 log buffers cho throughput cao |
| `logbsize=256k` | 256KB log buffer size |
| `allocsize=64m` | Pre-allocate 64MB cho large files |
| `inode64` | 64-bit inodes cho large filesystems |

---

## 9. Disk I/O - Block Device Tuning

### 9.1 Tuning Parameters

| Parameter | DATA | WAL | Reasoning |
|-----------|------|-----|-----------|
| `scheduler` | none | none | NVMe có hardware queue |
| `rotational` | 0 | 0 | Mark as SSD |
| `read_ahead_kb` | **64** | **4096** | Random: nhỏ, Sequential: lớn |
| `nr_requests` | 256 | 128 | Random cần queue lớn |
| `max_sectors_kb` | 128 | 1024 | Limit I/O size |
| `rq_affinity` | 2 | 2 | Complete I/O on same CPU |
| `add_random` | 0 | 0 | Không feed entropy pool |

### 9.2 read_ahead_kb Explanation

```
┌─────────────────────────────────────────────────────────────────────┐
│                    READ_AHEAD TUNING                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  DATA Volume: read_ahead_kb = 64                                    │
│  ───────────────────────────────────────────────────────────────   │
│  PostgreSQL reads 8KB pages randomly                               │
│  Read-ahead lớn = Prefetch data không dùng = Waste I/O             │
│  64KB = 8 pages = Đủ cho small prefetch                            │
│                                                                     │
│  WAL Volume: read_ahead_kb = 4096                                   │
│  ───────────────────────────────────────────────────────────────   │
│  WAL reads sequential (recovery, replication)                      │
│  Read-ahead lớn = Prefetch hiệu quả = Higher throughput            │
│  4MB = Prefetch nhiều WAL segments cùng lúc                        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 9.3 Tuning Order (QUAN TRỌNG!)

```bash
# PHẢI set rotational=0 TRƯỚC các tham số khác!
# Lý do: Setting rotational=0 → Kernel reset read_ahead_kb về default

# Đúng thứ tự:
echo 0 > /sys/block/nvmeXn1/queue/rotational      # 1. Mark as SSD
echo none > /sys/block/nvmeXn1/queue/scheduler    # 2. No scheduler
echo 64 > /sys/block/nvmeXn1/queue/read_ahead_kb  # 3. Set read_ahead
```

---

## 10. Measured Performance

### 10.1 Disk Benchmark Results (FIO)

| Scenario | Metric | Value | Note |
|----------|--------|-------|------|
| **data_latency** | Random Read Latency | **0.6ms** | Excellent for EBS |
| **data_stress** | Mixed IOPS | **18,700** | Read 13.1K + Write 5.6K |
| **data_throughput** | Seq Read | **1,003 MB/s** | Near theoretical |
| **data_rand_write** | Random Write | **12,200 IOPS** | Near ceiling |
| **wal_heartbeat** | Sync IOPS | **536** | QD1 + fsync |
| **wal_trafficjam** | Group IOPS | **16,200** | Concurrent syncs |
| **wal_firehose** | Seq Write | **508 MB/s** | Checkpoint speed |

### 10.2 Theoretical vs Measured

| Metric | Theoretical | Measured | Efficiency |
|--------|-------------|----------|------------|
| Read IOPS | 24,000 | ~19,000 | 79% |
| Write IOPS | 12,000 | ~12,200 | 100%+ |
| Throughput | 500 MB/s | ~600 MB/s | 120% |
| Random Latency | 1.5-2.5ms | **0.6ms** | Excellent |

---

## 11. Full Configuration

### 11.1 sysctl.conf

```bash
# =============================================================================
# /etc/sysctl.d/99-postgresql.conf
# =============================================================================

# --- MEMORY: Aggressive Dirty Page Flushing ---
vm.swappiness = 1
vm.dirty_background_ratio = 1
vm.dirty_ratio = 4
vm.dirty_expire_centisecs = 200
vm.dirty_writeback_centisecs = 100
vm.overcommit_memory = 2
vm.overcommit_ratio = 80
vm.min_free_kbytes = 102400
vm.zone_reclaim_mode = 0

# --- FILE DESCRIPTORS ---
fs.file-max = 2097152
fs.aio-max-nr = 1048576

# --- NETWORK/TCP ---
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 2048
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15

# --- SCHEDULER ---
kernel.sched_autogroup_enabled = 0
kernel.numa_balancing = 0
kernel.sem = 250 32000 100 128
```

### 11.2 limits.conf

```bash
# /etc/security/limits.conf
postgres soft nofile 65535
postgres hard nofile 65535
postgres soft nproc 65535
postgres hard nproc 65535
```

### 11.3 THP Disable

```bash
# /etc/rc.local or systemd service
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
```

---

## 12. Tuning Impact Summary

### 12.1 OS Tuning Impact

| Parameter | Impact | Priority |
|-----------|--------|----------|
| `vm.dirty_background_ratio=1` | **+20% TPS** | Critical |
| `vm.dirty_writeback_centisecs=100` | **+15% TPS** | Critical |
| `vm.swappiness=1` | Prevent disasters | Critical |
| THP disabled | Stable latency | Critical |
| `vm.dirty_expire_centisecs=200` | +5% stability | Recommended |

### 12.2 Disk Tuning Impact

| Parameter | Impact | Priority |
|-----------|--------|----------|
| RAID10 chunk alignment | Prevent split I/O | Critical |
| XFS stripe alignment | +10% throughput | Critical |
| `read_ahead_kb` tuning | +5% random IOPS | Recommended |
| `scheduler=none` | -0.1ms latency | Nice-to-have |

### 12.3 Tuning Checklist

```
□ vm.dirty_background_ratio = 1
□ vm.dirty_ratio = 4
□ vm.dirty_expire_centisecs = 200
□ vm.dirty_writeback_centisecs = 100
□ vm.swappiness = 1
□ THP disabled (enabled=never, defrag=never)
□ RAID10 chunk size: DATA=64KB, WAL=256KB
□ XFS aligned to RAID stripe
□ read_ahead_kb: DATA=64, WAL=4096
□ scheduler=none for NVMe
```

---

## 13. Troubleshooting

### 13.1 Check Dirty Pages

```bash
# Xem dirty pages hiện tại
grep -E "Dirty|Writeback" /proc/meminfo

# Good: Dirty < 200MB
# Bad: Dirty > 600MB (approaching dirty_ratio)
```

### 13.2 Check THP Status

```bash
cat /sys/kernel/mm/transparent_hugepage/enabled
# Should show: always madvise [never]

cat /sys/kernel/mm/transparent_hugepage/defrag
# Should show: always defer defer+madvise madvise [never]
```

### 13.3 Check Block Device Settings

```bash
# Check read_ahead
cat /sys/block/md0/queue/read_ahead_kb  # Should be 64
cat /sys/block/md1/queue/read_ahead_kb  # Should be 4096

# Check scheduler
cat /sys/block/nvme*/queue/scheduler    # Should be [none]
```

### 13.4 Monitor I/O Cliff

```bash
# Watch dirty pages during benchmark
watch -n 1 'grep -E "Dirty|Writeback" /proc/meminfo'

# If Dirty spikes to 600MB+ → dirty_ratio blocking writes
# If Writeback stays high → disk can't keep up
```

---

## 14. References

- [PostgresAI - Linux OLTP Tuning](https://postgres.ai/docs/postgres-howtos/database-administration/configuration/how-to-tune-linux-parameters-for-oltp-postgres)
- [XFS RAID10 Formatting](https://blog.tsunanet.net/2011/08/mkfsxfs-raid10-optimal-performance.html)
- [Linux Kernel - Queue sysfs](https://www.kernel.org/doc/html/v5.3/block/queue-sysfs.html)
- [Red Hat - Tuning Virtual Memory](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/performance_tuning_guide/sect-red_hat_enterprise_linux-performance_tuning_guide-memory-tuning)
