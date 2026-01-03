# PostgreSQL OLTP Benchmark - Case Study

Tài liệu chi tiết về quá trình benchmark và tuning PostgreSQL heavy-write OLTP trên AWS EBS gp3 RAID10.

---

## 1. Workload Profile

### 1.1 pgbench TPC-B

| Attribute | Value | Note |
|-----------|-------|------|
| **Benchmark** | pgbench TPC-B-like | Standard OLTP benchmark |
| **Scale Factor** | 1250 | 125 triệu accounts |
| **Clients** | 100 | Concurrent connections |
| **Threads** | 6 | pgbench worker threads |
| **Duration** | 60s | Per test run |

### 1.2 Dataset Size

```
┌─────────────────────────────────────────────────────────────────────┐
│                     DATASET COMPOSITION                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   pgbench_accounts      : 18 GB    (125M rows × 150 bytes)         │
│   pgbench_accounts_pkey : 2.7 GB   (B-tree index)                  │
│   pgbench_history       : ~30 MB   (grows during benchmark)        │
│   pgbench_tellers       : 1.7 MB   (12,500 rows)                   │
│   pgbench_branches      : 0.5 MB   (1,250 rows)                    │
│   ─────────────────────────────────────────────────────────        │
│   TOTAL DATASET         : ~21 GB                                    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.3 Workload Characteristics

| Metric | Value | Impact |
|--------|-------|--------|
| **Read:Write Ratio** | ~70:30 | Heavy write OLTP |
| **Working Set** | ~21 GB | 5x larger than shared_buffers |
| **I/O Pattern** | Random 8KB | PostgreSQL page size |
| **Durability** | synchronous_commit=on | Every commit syncs to WAL |

**TPC-B Transaction Flow:**
```
BEGIN;
  UPDATE pgbench_accounts SET abalance = abalance + $delta WHERE aid = $aid;
  SELECT abalance FROM pgbench_accounts WHERE aid = $aid;
  UPDATE pgbench_tellers SET tbalance = tbalance + $delta WHERE tid = $tid;
  UPDATE pgbench_branches SET bbalance = bbalance + $delta WHERE bid = $bid;
  INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (...);
COMMIT;  -- WAL sync here!
```

---

## 2. Hardware Specification

### 2.1 Instance

| Component | Spec | Cost (us-west-2) |
|-----------|------|------------------|
| **Instance** | c7g.2xlarge | $0.289/hour |
| **vCPU** | 8 (Graviton3) | ARM64 |
| **RAM** | 16 GB | |
| **Network** | Up to 15 Gbps | |
| **EBS Bandwidth** | Up to 10 Gbps | |

### 2.2 Storage

| Volume | Disks | Size | RAID | Usable | Cost |
|--------|-------|------|------|--------|------|
| **DATA** | 8× gp3 | 50 GB each | RAID10 | 200 GB | $0.064/GB/mo × 400GB |
| **WAL** | 8× gp3 | 30 GB each | RAID10 | 120 GB | $0.064/GB/mo × 240GB |

**EBS gp3 Specs (per disk):**
| Metric | Baseline | Provisioned |
|--------|----------|-------------|
| IOPS | 3,000 | 3,000 (included) |
| Throughput | 125 MB/s | 125 MB/s (included) |
| Latency | 1.5-2.5 ms | Network storage |

### 2.3 Storage Architecture Philosophy

```
┌─────────────────────────────────────────────────────────────────────┐
│              HORIZONTAL SCALING STORAGE (The "Secret Weapon")        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   Concept: Gộp nhiều ổ nhỏ rẻ tiền thành 1 ổ lớn hiệu năng cao     │
│                                                                     │
│   Traditional (Vertical):                                           │
│   ┌─────────────────────────────────────────────────────────┐      │
│   │  1× io2 Block Express (660GB, 20k IOPS) = $1,122/month  │      │
│   └─────────────────────────────────────────────────────────┘      │
│                                                                     │
│   Our Approach (Horizontal):                                        │
│   ┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐│
│   │ gp3  ││ gp3  ││ gp3  ││ gp3  ││ gp3  ││ gp3  ││ gp3  ││ gp3  ││
│   │ 50GB ││ 50GB ││ 50GB ││ 50GB ││ 50GB ││ 50GB ││ 50GB ││ 50GB ││
│   │ 3K   ││ 3K   ││ 3K   ││ 3K   ││ 3K   ││ 3K   ││ 3K   ││ 3K   ││
│   └──┬───┘└──┬───┘└──┬───┘└──┬───┘└──┬───┘└──┬───┘└──┬───┘└──┬───┘│
│      └───────┴───────┴───────┼───────┴───────┴───────┴───────┘     │
│                              ▼                                      │
│                    ┌─────────────────┐                              │
│                    │   RAID10 md0    │                              │
│                    │   ~19K IOPS     │                              │
│                    │   ~600 MB/s     │                              │
│                    └─────────────────┘                              │
│                                                                     │
│   Trade-off: Setup phức tạp hơn (Terraform/mdadm) nhưng tiết kiệm  │
│   ~87% chi phí so với giải pháp Enterprise.                        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.4 Theoretical vs Measured Performance

| Metric | Theoretical | Measured (fio) | Efficiency |
|--------|-------------|----------------|------------|
| **Read IOPS** | 24,000 | ~19,000 | 79% |
| **Write IOPS** | 12,000 | ~12,200 | 100%+ |
| **Throughput** | 500 MB/s | ~600 MB/s | 120% |
| **Random Read Latency** | 1.5-2.5ms | **0.6ms** | Excellent |

```
┌─────────────────────────────────────────────────────────────────────┐
│                     RAID10 CEILING CALCULATION                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   READ IOPS  = 8 disks × 3000 IOPS = 24,000 IOPS                   │
│   WRITE IOPS = 4 stripes × 3000 IOPS = 12,000 IOPS (mirror 2x)     │
│   THROUGHPUT = 4 stripes × 125 MB/s = 500 MB/s                     │
│                                                                     │
│   WAL QD1+fsync = 1000ms / 1.85ms latency = ~540 IOPS              │
│   (Single-thread commit bottleneck - vượt qua bằng Group Commit)   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.5 Hardware vs Dataset Analysis

```
┌─────────────────────────────────────────────────────────────────────┐
│                     MEMORY vs DATASET GAP                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   shared_buffers = 4 GB                                             │
│   Dataset        = 21 GB                                            │
│   Ratio          = 21 / 4 = 5.25x                                  │
│                                                                     │
│   Consequence: ~80% của working set KHÔNG nằm trong buffer cache   │
│   → Cache miss rate cao                                             │
│   → Random I/O đến disk liên tục                                   │
│   → Backend process phải chờ I/O                                   │
│                                                                     │
│   Nếu shared_buffers = 24GB (> dataset):                           │
│   → Hầu hết data trong RAM                                          │
│   → TPS có thể đạt 30-50K (CPU-bound thay vì I/O-bound)            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. Tuning Journey

### 3.1 Phase 1: Baseline (Default PostgreSQL + Default OS)

**Configuration:**
```bash
# OS (Ubuntu defaults)
vm.swappiness = 60
vm.dirty_background_ratio = 10      # Chờ 10% RAM bẩn mới xả nền
vm.dirty_ratio = 20                 # Chờ 20% RAM bẩn mới block
vm.dirty_expire_centisecs = 3000    # Data nằm trong RAM 30 giây
vm.dirty_writeback_centisecs = 500  # Quét rác mỗi 5 giây

# PostgreSQL (mostly defaults)
shared_buffers = 4GB
bgwriter_delay = 200ms              # Dọn buffer mỗi 200ms (5 lần/giây)
bgwriter_lru_maxpages = 100         # Chỉ dọn max 100 pages/round
bgwriter_lru_multiplier = 2.0       # Dọn ít, để dành cho backend
wal_writer_delay = 200ms
checkpoint_timeout = 5min
max_wal_size = 1GB
```

**Kết quả Benchmark (Baseline):**

```
┌─────────────────────────────────────────────────────────────────────┐
│                    THE "I/O CLIFF" (Vách đá I/O)                    │
├─────────────────────────────────────────────────────────────────────┤
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
│       (RAM)    (DISK - I/O CLIFF!)                                 │
│                                                                     │
│   Giải thích:                                                       │
│   • 0-20s: Writes đi vào RAM (OS Page Cache) → TPS cao (~17K)      │
│   • 20s+: RAM đầy, OS flush cục bộ 3GB xuống đĩa cùng lúc          │
│           → Disk bị nghẽn → TPS tụt thảm hại (~5-7K)               │
│           → Latency spike lên 100ms+                               │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

| Metric | Value | Note |
|--------|-------|------|
| TPS (peak) | ~17,000 | 0-20s, ghi vào RAM |
| TPS (after cliff) | ~5,000-7,000 | 20s+, disk flush |
| Latency (peak) | **100ms+** | Spike khi flush |
| I/O Cliff severity | **50-70% drop** | Nghiêm trọng |

**Root Cause Analysis:**

```
┌─────────────────────────────────────────────────────────────────────┐
│                    WHY I/O CLIFF HAPPENS?                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   Timeline của Dirty Pages với Default Config:                      │
│                                                                     │
│   RAM (16GB)                                                        │
│   ┌──────────────────────────────────────────────────────────────┐ │
│   │                                                              │ │
│   │  dirty_background_ratio=10 (1.6GB) ─────────────────────────│ │
│   │  ▲                                                           │ │
│   │  │  dirty pages tích tụ từ từ...                            │ │
│   │  │  ██████████████████████████                              │ │
│   │  │  ██████████████████████████  (30 giây không ai dọn)      │ │
│   │  │  ██████████████████████████                              │ │
│   │  │  ██████████████████████████                              │ │
│   │  │  ██████████████████████████                              │ │
│   │  │  ██████████████████████████ ← Đạt 1.6GB, BẮT ĐẦU FLUSH!  │ │
│   │  │                                                           │ │
│   │  └──► FLUSH 1.6GB CÙNG LÚC = DISK NGHẼN!                    │ │
│   │                                                              │ │
│   └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│   Vấn đề:                                                           │
│   1. OS "lười" - đợi 10% RAM (1.6GB) mới xả                        │
│   2. Data nằm lỳ 30 giây - dồn cục                                 │
│   3. Bgwriter "ngủ nướng" - 200ms/lần, 100 pages/lần              │
│   4. Khi flush → toàn bộ băng thông đĩa bị chiếm                   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Key Problems:**
1. **Dirty Page Dồn Cục**: OS giữ dirty pages lâu (30s expire, 10% threshold) → flush đồng loạt 1.6GB
2. **Bgwriter Lười**: 200ms delay + 100 pages max = không kịp dọn buffer
3. **Backend Write Storm**: Khi không có clean page, backend tự ghi → TPS drop
4. **Checkpoint Storm**: Default 5min timeout + 1GB max_wal_size = checkpoint quá thường xuyên

---

### 3.2 Phase 2: OS Tuning (Aggressive Dirty Page Flushing)

**Configuration Changes:**
```bash
# Aggressive dirty page flushing
vm.swappiness = 1                    # Cấm swap
vm.dirty_background_ratio = 1        # Xả khi 1% RAM dirty (~150MB)
vm.dirty_ratio = 4                   # Block khi 4% dirty (~600MB)
vm.dirty_expire_centisecs = 200      # Data max 2s trong RAM
vm.dirty_writeback_centisecs = 100   # Flush thread mỗi 1s
```

**Results:**
| Metric | Baseline | After OS Tuning | Change |
|--------|----------|-----------------|--------|
| **TPS (avg)** | ~7,000 | **9,912** | +41% |
| **TPS (peak)** | ~12,000 | **15,263** | +27% |
| buffers_backend | Very high | 236,217 | Reduced |

**TPS Timeline:**
```
Time    TPS      Observation
─────   ─────    ────────────────────────────────
 5s     15,263   Peak performance
10s     15,361   Still high
15s     11,322   ← Checkpoint starting
20s      9,458   Checkpoint impact
25s      8,772   I/O saturation
30s      8,500   Steady state (I/O cliff)
```

**Key Observations:**
1. **I/O Cliff vẫn xảy ra** nhưng ít nghiêm trọng hơn
2. **Dirty pages không dồn cục** - flush liên tục mỗi giây
3. **buffers_backend giảm 48%** - bgwriter làm nhiều việc hơn
4. **TPS ổn định hơn** trong 10s đầu

**Vấn đề còn lại:**
- Bgwriter vẫn chưa đủ nhanh (200ms delay)
- Checkpoint vẫn gây contention
- WAL writer chưa được tune

---

### 3.3 Phase 3: PostgreSQL Tuning (Aggressive Background Writer + Group Commit)

**Strategy: "Offloading & Batching"**

```
┌─────────────────────────────────────────────────────────────────────┐
│                    TUNING STRATEGY                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   1. OFFLOADING: Chuyển việc ghi từ Backend sang Bgwriter          │
│      Backend (User Process) chỉ nên xử lý Query, không nên I/O     │
│                                                                     │
│   2. BATCHING (Group Commit): Gom nhiều COMMIT vào 1 fsync         │
│      EBS fsync = ~1.8ms (bottleneck vật lý, không thể tránh)       │
│      → Thay vì 1 commit/fsync, gom 10 commits/fsync                │
│      → Throughput tăng 10x với cùng số lần fsync                   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Configuration Changes:**
```bash
# Background Writer - Siêu tích cực (Offloading)
bgwriter_delay = 10ms                # 100 lần/giây (thay vì 5 lần)
bgwriter_lru_maxpages = 1000         # Max 1000 pages/round = 8MB/round
bgwriter_lru_multiplier = 10.0       # Dọn dư 10x, luôn có clean pages

# WAL Writer - Flush liên tục
wal_writer_delay = 10ms              # Giảm WALWrite lock contention

# Group Commit - Batching để vượt qua fsync bottleneck
commit_delay = 50                    # Đợi 50µs để gom transactions
commit_siblings = 10                 # Chỉ đợi khi có ≥10 concurrent commits

# Checkpoint - Thưa hơn, spread out
checkpoint_timeout = 30min           # Tăng từ 15min
max_wal_size = 48GB                  # Buffer lớn hơn
min_wal_size = 4GB

# Autovacuum - Thả xích (vì đĩa chịu được)
autovacuum_vacuum_cost_limit = 10000 # 50x default
```

**Group Commit Explained:**

```
┌─────────────────────────────────────────────────────────────────────┐
│                    GROUP COMMIT MECHANISM                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   WITHOUT Group Commit (commit_delay = 0):                          │
│   ─────────────────────────────────────────                         │
│   TX1: COMMIT ───► fsync (1.8ms) ───► Done                         │
│   TX2:     COMMIT ───► fsync (1.8ms) ───► Done                     │
│   TX3:         COMMIT ───► fsync (1.8ms) ───► Done                 │
│   │                                                                 │
│   Total: 3 fsyncs × 1.8ms = 5.4ms                                  │
│   Max throughput: 1000/1.8 ≈ 555 commits/second (single-thread)    │
│                                                                     │
│   WITH Group Commit (commit_delay = 50µs):                          │
│   ───────────────────────────────────────                           │
│   TX1: COMMIT ─┐                                                    │
│   TX2: COMMIT ─┼──► (wait 50µs) ──► fsync (1.8ms) ───► All Done   │
│   TX3: COMMIT ─┘                                                    │
│   │                                                                 │
│   Total: 1 fsync × 1.8ms = 1.8ms for 3 commits                     │
│   Effective: 0.6ms per commit (3x faster!)                         │
│                                                                     │
│   Điều kiện: commit_siblings = 10                                   │
│   → Chỉ đợi khi có ≥10 backends đang commit đồng thời              │
│   → Tránh đợi vô nghĩa khi hệ thống idle                           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Results:**
| Metric | After OS Tuning | After PG Tuning | Change |
|--------|-----------------|-----------------|--------|
| **TPS (avg)** | 9,912 | **11,469** | **+16%** |
| **TPS (peak)** | 15,263 | **15,553** | +2% |
| **Latency (avg)** | 10.05 ms | **8.70 ms** | -13% |
| buffers_clean | 31,359 | **126,564** | **+304%** |

**TPS Timeline Comparison:**
```
Time    Before PG Tune    After PG Tune    Improvement
─────   ──────────────    ─────────────    ───────────
 5s     15,263            15,553           +2%
10s     15,361            14,414           -6% (natural variance)
15s     11,322            13,712           +21% ← Key improvement!
20s      9,458            13,447           +42% ← Key improvement!
25s      8,772            13,947           +59% ← Key improvement!
30s      8,500            10,613           +25%
35s      8,415             7,840           -7% (checkpoint)
40s      8,570            11,347           +32%
```

**Key Observations:**
1. **TPS stays high longer**: 13-14K TPS maintained for 25s (vs dropping at 15s)
2. **Bgwriter làm việc gấp 4x**: 126K buffers_clean vs 31K
3. **I/O cliff delay**: Xảy ra muộn hơn (30s thay vì 15s)
4. **Recovery nhanh hơn**: Sau checkpoint, TPS phục hồi nhanh

---

## 4. Final State - Optimized Configuration

### 4.1 OS Configuration (`/etc/sysctl.conf`)

```bash
# Memory - Aggressive dirty page flushing
vm.swappiness = 1
vm.dirty_background_ratio = 1
vm.dirty_ratio = 4
vm.dirty_expire_centisecs = 200
vm.dirty_writeback_centisecs = 100
vm.overcommit_memory = 2
vm.overcommit_ratio = 80
vm.min_free_kbytes = 102400

# Network
net.core.somaxconn = 4096
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15

# Scheduler
kernel.sched_autogroup_enabled = 0
kernel.numa_balancing = 0
```

### 4.2 RAID Configuration

```bash
# DATA Volume (Random I/O)
RAID Level: RAID10
Chunk Size: 64KB          # Fit 8KB PostgreSQL pages
read_ahead_kb: 64         # Small for random I/O
Mount: noatime,nodiratime,allocsize=64m

# WAL Volume (Sequential I/O)
RAID Level: RAID10
Chunk Size: 256KB         # Large for sequential
read_ahead_kb: 4096       # Large for sequential prefetch
Mount: noatime,nodiratime
```

### 4.3 PostgreSQL Configuration

```bash
# Memory
shared_buffers = 4GB
effective_cache_size = 11GB
work_mem = 32MB
maintenance_work_mem = 1GB

# Background Writer (Aggressive) - THE SECRET SAUCE
bgwriter_delay = 10ms               # 100x/sec thay vì 5x/sec
bgwriter_lru_maxpages = 1000        # 8MB/round
bgwriter_lru_multiplier = 10.0      # Luôn có clean pages sẵn

# WAL
wal_compression = lz4               # Graviton3 có SIMD optimization cho LZ4
wal_buffers = 64MB
wal_writer_delay = 10ms             # Giảm WALWrite lock contention

# Group Commit - Bypass fsync bottleneck
commit_delay = 50                   # 50µs wait để gom commits
commit_siblings = 10                # Chỉ đợi khi ≥10 concurrent

# Checkpoint (Sparse) - Reduce I/O contention
checkpoint_timeout = 30min
max_wal_size = 48GB
min_wal_size = 4GB
checkpoint_completion_target = 0.9

# I/O - Based on FIO benchmark results
random_page_cost = 1.1              # FIO measured: 0.6ms random latency
effective_io_concurrency = 200      # RAID10 8 disks parallel

# Autovacuum (Aggressive) - Disk can handle it
autovacuum_vacuum_cost_limit = 10000  # 50x default, "thả xích"
```

**Tại sao các giá trị này?**

| Parameter | Value | Reasoning |
|-----------|-------|-----------|
| `random_page_cost=1.1` | Based on FIO: 0.6ms random read | SSD/NVMe ratio gần = seq |
| `effective_io_concurrency=200` | RAID10 8 disks | Nhiều concurrent I/O |
| `wal_compression=lz4` | Graviton3 SIMD | LZ4 rất nhanh trên ARM64 |
| `bgwriter_delay=10ms` | 100x/sec | Real-time buffer cleaning |
| `commit_delay=50` | 50µs | Gom commits mà không delay quá lâu |

### 4.4 Final Performance

| Metric | Value | Note |
|--------|-------|------|
| **TPS (average)** | **11,469** | Over 60s sustained |
| **TPS (peak)** | **15,553** | First 5 seconds |
| **TPS (minimum)** | **6,285** | During checkpoint |
| **Latency (avg)** | **8.70 ms** | 100 clients |
| **Latency (p99)** | ~50 ms | Acceptable |

---

## 5. Performance vs Cost Analysis

### 5.1 Infrastructure Cost (Monthly)

| Component | Spec | Cost/Month |
|-----------|------|------------|
| EC2 c7g.2xlarge | On-Demand | $208.08 |
| EBS DATA | 8× 50GB gp3 | $25.60 |
| EBS WAL | 8× 30GB gp3 | $15.36 |
| **Total** | | **$249.04** |

**With Spot Instance (70% discount):**
| Component | Spec | Cost/Month |
|-----------|------|------------|
| EC2 c7g.2xlarge | Spot (~$0.087/hr) | $62.64 |
| EBS DATA | 8× 50GB gp3 | $25.60 |
| EBS WAL | 8× 30GB gp3 | $15.36 |
| **Total** | | **$103.60** |

### 5.2 So sánh với Enterprise Solution (io2 Block Express)

```
┌─────────────────────────────────────────────────────────────────────┐
│              HORIZONTAL SCALING vs VERTICAL SCALING                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   OPTION A: Traditional Enterprise (Vertical)                       │
│   ───────────────────────────────────────────                       │
│   • 1× io2 Block Express 660GB, 20K IOPS                           │
│   • Cost: ~$1,122/month                                             │
│   • Latency: < 1ms (excellent)                                      │
│   • Setup: Simple (1 volume)                                        │
│                                                                     │
│   OPTION B: Our Solution (Horizontal)                               │
│   ─────────────────────────────────────                             │
│   • 16× gp3 RAID10 + Spot Instance                                  │
│   • Cost: ~$150/month (Spot) / ~$250 (On-Demand)                   │
│   • Latency: 0.6ms (measured - also excellent!)                     │
│   • Setup: Complex (Terraform + mdadm)                              │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

| Aspect | io2 Block Express | Our RAID10 Solution | Winner |
|--------|-------------------|---------------------|--------|
| **Cost/Month** | $1,122 | **$150** (Spot) | RAID10 (-87%) |
| **IOPS** | 20,000 | **19,000** | Comparable |
| **Latency** | < 1ms | **0.6ms** | Comparable |
| **Throughput** | 500 MB/s | **600 MB/s** | RAID10 |
| **Setup Complexity** | **Simple** | Complex | io2 |
| **Fault Tolerance** | **EBS native** | RAID10 mirror | io2 |

**Kết luận:**
- **Tiết kiệm ~87% chi phí** so với giải pháp Enterprise
- **Hiệu năng tương đương 95%** (19K vs 20K IOPS)
- **Trade-off**: Setup phức tạp hơn (cần Terraform/Ansible automation)
- **Use case**: Phù hợp cho dev/staging, startups cần tối ưu cost, hoặc khi có DevOps team maintain

### 5.3 Performance Metrics

```
┌─────────────────────────────────────────────────────────────────────┐
│                     PERFORMANCE SUMMARY                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   TPS Achieved:     11,469 transactions/second                      │
│   Monthly TPS:      11,469 × 60 × 60 × 24 × 30 = 29.7 billion      │
│                                                                     │
│   Cost per Million TPS:                                             │
│   - On-Demand: $249.04 / 29,700M = $0.0084 per million TPS         │
│   - Spot:      $103.60 / 29,700M = $0.0035 per million TPS         │
│                                                                     │
│   Latency:                                                          │
│   - Average: 8.70 ms (excellent for OLTP)                          │
│   - p99: ~50 ms (acceptable)                                        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 5.4 Scaling Options

| Option | Change | Expected Result | Cost Impact |
|--------|--------|-----------------|-------------|
| **More RAM** | c7g.4xlarge (32GB) | +30-50% TPS | +$208/mo |
| **More IOPS** | Provision 6000 IOPS/disk | +20-30% TPS | +$160/mo |
| **io2 Block Express** | Replace gp3 with io2 | +50% TPS, lower latency | +$500/mo |
| **Larger shared_buffers** | 24GB (> dataset) | +100-200% TPS | Requires larger instance |

### 5.5 Efficiency Analysis

```
┌─────────────────────────────────────────────────────────────────────┐
│                     EFFICIENCY METRICS                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   Hardware Utilization:                                             │
│   - CPU: ~60-70% (room for growth)                                  │
│   - RAM: ~90% (tight, could benefit from more)                      │
│   - Disk IOPS: ~80-90% at peak (near saturation)                   │
│   - Disk Throughput: ~50% (not bandwidth limited)                  │
│                                                                     │
│   Bottleneck Analysis:                                              │
│   1. Primary: EBS IOPS (gp3 3000 IOPS/disk limit)                  │
│   2. Secondary: shared_buffers < dataset (cache miss)              │
│   3. Tertiary: Checkpoint I/O contention                           │
│                                                                     │
│   TPS per Dollar (Spot):                                            │
│   11,469 TPS / $103.60 = 110.7 TPS per dollar per month            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 6. Key Learnings

### 6.1 OS Tuning Impact

| Parameter | Impact | Priority |
|-----------|--------|----------|
| `vm.dirty_background_ratio=1` | **High** - Early flush prevents storm | Must-have |
| `vm.dirty_writeback_centisecs=100` | **High** - Continuous flush | Must-have |
| `vm.swappiness=1` | **Medium** - Prevent swap | Must-have |
| `vm.dirty_expire_centisecs=200` | **Medium** - Fresh data | Nice-to-have |

### 6.2 PostgreSQL Tuning Impact

| Parameter | Impact | Priority |
|-----------|--------|----------|
| `bgwriter_delay=10ms` | **Critical** - 4x more buffer cleaning | Must-have |
| `bgwriter_lru_multiplier=10.0` | **High** - Proactive cleaning | Must-have |
| `commit_delay=50` | **High** - Group commit bypass fsync | Recommended |
| `wal_writer_delay=10ms` | **Medium** - Reduce WAL contention | Recommended |
| `checkpoint_timeout=30min` | **Medium** - Reduce checkpoint frequency | Recommended |
| `autovacuum_vacuum_cost_limit=10000` | **Medium** - Fast vacuum khi disk mạnh | Recommended |
| `max_wal_size=48GB` | **Low** - Support longer checkpoint interval | Optional |

### 6.3 Common Mistakes to Avoid

```
❌ Mistake 1: Assuming more RAM = linear TPS increase
   → Reality: Diminishing returns after dataset fits in memory

❌ Mistake 2: Ignoring OS dirty page settings
   → Reality: OS flush storm can tank TPS regardless of PG tuning

❌ Mistake 3: Default bgwriter is sufficient
   → Reality: Default 200ms delay is too slow for heavy write

❌ Mistake 4: Tuning only checkpoint parameters
   → Reality: Need to tune bgwriter AND OS AND checkpoint together

❌ Mistake 5: Expecting linear IOPS scaling with more disks
   → Reality: EBS latency is the bottleneck for single-thread operations
```

### 6.4 Monitoring Checklist

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| `buffers_backend` ratio | <10% | 10-30% | >30% |
| `buffers_clean` | Increasing | Flat | Zero |
| `Dirty` in /proc/meminfo | <200MB | 200-600MB | >600MB |
| TPS variance | <20% | 20-50% | >50% |
| p99 latency | <50ms | 50-100ms | >100ms |

---

## 7. Conclusion

### Before vs After Summary

| Aspect | Baseline | Optimized | Improvement |
|--------|----------|-----------|-------------|
| TPS (avg) | ~7,000 | **11,469** | **+64%** |
| TPS stability | Severe cliff | Gradual decline | Much better |
| Latency (avg) | ~15 ms | **8.7 ms** | **-42%** |
| I/O cliff | 50-70% drop | 30-40% drop | Less severe |

### Cost-Effectiveness

```
Final Configuration delivers:
- 11,469 TPS sustained
- ~$100/month (Spot)
- $0.0035 per million transactions
- Suitable for medium-scale OLTP workloads
```

### When to Scale Up

Consider upgrading when:
1. **TPS consistently >10K needed** → Add more IOPS or larger instance
2. **Latency p99 >100ms** → Use io2 Block Express
3. **Dataset grows >50GB** → Increase shared_buffers and instance RAM
4. **Need HA** → Add streaming replica (doubles cost)

---

## Appendix: Quick Reference

### A. Benchmark Commands

```bash
# Run full benchmark
sudo python3 ~/scripts/bench.py --run 11

# Quick pgbench test
sudo -u postgres pgbench -c 100 -j 6 -T 60 -P 5 pgbench

# Check bgwriter stats
sudo -u postgres psql -c "SELECT * FROM pg_stat_bgwriter"

# Monitor dirty pages
watch -n 1 'grep -E "Dirty|Writeback" /proc/meminfo'

# Monitor wait events
sudo -u postgres psql -c "
SELECT wait_event_type, wait_event, count(*)
FROM pg_stat_activity
WHERE state = 'active'
GROUP BY 1, 2 ORDER BY 3 DESC"
```

### B. Configuration Files

| File | Purpose |
|------|---------|
| `/home/ubuntu/scripts/config.env` | All tuning parameters |
| `/etc/sysctl.d/99-postgresql.conf` | OS tuning |
| `/data/postgresql/postgresql.conf` | PostgreSQL config |

### C. Key Formulas

```
Max QD1 IOPS = 1000ms / EBS_latency_ms
RAID10 Write IOPS = (disk_count / 2) × disk_IOPS
buffers_backend_ratio = buffers_backend / buffers_alloc × 100%
TPS per dollar = TPS / monthly_cost
```
