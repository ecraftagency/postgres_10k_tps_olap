# PostgreSQL 16 Configuration Guide

Hướng dẫn cấu hình chi tiết PostgreSQL 16 cho heavy-write OLTP trên AWS Graviton + RAID10 EBS gp3.

**Achieved: 11,500 TPS** với synchronous_commit = on (Zero Data Loss)

---

> **⚠️ QUAN TRỌNG: Vị trí Config Files**
>
> Config files nằm trong **data directory**, KHÔNG PHẢI `/etc/postgresql/`:
>
> ```
> /data/postgresql/postgresql.conf   ← Main config
> /data/postgresql/pg_hba.conf       ← Authentication rules
> /data/postgresql/pg_ident.conf     ← User mapping
> ```
>
> File `/etc/postgresql/16/main/postgresql.conf` chỉ là **pointer** đến data directory.
>
> **Authentication:**
> - VPC internal (`10.0.0.0/8`): `trust` - không cần password (cho PgCat, replicas)
> - External: `scram-sha-256` - password = `benchmark`

---

## 1. Hardware Context

```
┌─────────────────────────────────────────────────────────────────────┐
│                       SYSTEM OVERVIEW                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  EC2: c8g.2xlarge (Graviton 4, ARM64)                         │ │
│  │  - 8 vCPU                                                     │ │
│  │  - 16 GB RAM                                                  │ │
│  │  - EBS Bandwidth: ~10 Gbps                                    │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌─────────────────────────┐    ┌─────────────────────────┐        │
│  │  DATA: /dev/md0         │    │  WAL: /dev/md1          │        │
│  │  8× gp3 RAID10          │    │  8× gp3 RAID10          │        │
│  │  200 GB usable          │    │  120 GB usable          │        │
│  │  Chunk: 64KB            │    │  Chunk: 256KB           │        │
│  │  ~19K IOPS measured     │    │  ~19K IOPS measured     │        │
│  └─────────────────────────┘    └─────────────────────────┘        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Benchmark Results (Disk)

| Scenario | Metric | Value | Ý nghĩa cho PostgreSQL |
|----------|--------|-------|------------------------|
| **wal_heartbeat** | Sync IOPS | 536 | Max single-thread commits/sec |
| **wal_heartbeat** | Latency | 1.85ms | Commit latency (EBS round-trip) |
| **wal_trafficjam** | Group IOPS | 16,200 | Max concurrent commits/sec |
| **data_latency** | Read Latency | **0.6ms** | random_page_cost basis |
| **data_stress** | Mixed IOPS | 18,700 | Read 13.1K + Write 5.6K |
| **data_throughput** | Seq Read | 1,003 MB/s | Full table scan speed |

---

## 2. Memory Configuration

### 2.1 Memory Allocation Strategy

```
┌─────────────────────────────────────────────────────────────────────┐
│                       MEMORY ALLOCATION (16GB)                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  shared_buffers = 4 GB (25% RAM)                              │ │
│  │  ─────────────────────────────────────────────────────────    │ │
│  │  • PostgreSQL buffer pool                                     │ │
│  │  • Hot data cached here                                       │ │
│  │  • 4GB < 21GB dataset → Cache miss → Disk I/O                │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  OS Page Cache ≈ 11 GB                                        │ │
│  │  ─────────────────────────────────────────────────────────    │ │
│  │  • Linux auto-cache file I/O                                  │ │
│  │  • effective_cache_size = 11GB (hint to planner)             │ │
│  │  • Seq read: 1 GB/s (from benchmark)                         │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  PostgreSQL Processes ≈ 1 GB                                  │ │
│  │  ─────────────────────────────────────────────────────────    │ │
│  │  • Backend processes (max 300)                                │ │
│  │  • work_mem = 32MB per sort/hash                             │ │
│  │  • maintenance_work_mem = 1GB                                │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 Memory Parameters

| Parameter | Value | Reasoning |
|-----------|-------|-----------|
| `shared_buffers` | **4GB** | 25% RAM, đủ cho hot data |
| `effective_cache_size` | **11GB** | shared_buffers + OS cache estimate |
| `work_mem` | **32MB** | Per-sort operation, sweet spot cho OLTP |
| `maintenance_work_mem` | **1GB** | Fast VACUUM/CREATE INDEX |

**Tại sao 4GB, không phải 8GB?**
- Dataset = 21GB, nếu shared_buffers = 24GB → toàn bộ trong RAM → CPU-bound
- Với 4GB → cache miss → test được disk I/O thực sự
- OLTP queries nhỏ, không cần buffer pool khổng lồ

---

## 3. Disk I/O Configuration

### 3.1 Cost Model Tuning

```
┌─────────────────────────────────────────────────────────────────────┐
│                    COST MODEL: SEQUENTIAL vs RANDOM                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  PostgreSQL Defaults (thiết kế cho HDD):                           │
│    seq_page_cost = 1.0                                              │
│    random_page_cost = 4.0   ← Random chậm hơn 4x seq trên HDD      │
│                                                                     │
│  FIO Benchmark Results (NVMe/EBS):                                  │
│    Random read latency:  0.6ms                                      │
│    Seq read latency:     ~0.008ms per page (1003 MB/s ÷ 8KB)       │
│                                                                     │
│  Thực tế trên EBS:                                                  │
│    Random ≈ Sequential (cả hai đều qua network)                    │
│    → random_page_cost = 1.1 (gần bằng seq)                         │
│                                                                     │
│  Impact:                                                            │
│    • Planner prefer Index Scan hơn Seq Scan                        │
│    • Tốt cho OLTP (point queries, indexed lookups)                 │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.2 I/O Concurrency

| Parameter | Value | Reasoning |
|-----------|-------|-----------|
| `random_page_cost` | **1.1** | Based on FIO: 0.6ms random latency |
| `seq_page_cost` | **1.0** | Baseline |
| `effective_io_concurrency` | **200** | RAID10 8 disks = nhiều parallel I/O |

---

## 4. WAL Configuration

### 4.1 Commit Path & TPS Ceiling

```
┌─────────────────────────────────────────────────────────────────────┐
│                    COMMIT PATH & TPS CEILING                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Mỗi COMMIT (synchronous_commit = on):                             │
│    1. Write WAL record vào WAL buffer                               │
│    2. fsync() WAL buffer ra disk  ← BOTTLENECK: 1.85ms             │
│    3. Return SUCCESS cho client                                     │
│                                                                     │
│  Single-thread ceiling:                                             │
│    Max TPS = 1000ms / 1.85ms = 540 TPS                             │
│                                                                     │
│  Giải pháp bypass bottleneck:                                       │
│    1. Parallel backends: 20 threads × 540 = 10,800 TPS             │
│    2. Group Commit: gom N commits vào 1 fsync                      │
│                                                                     │
│  Benchmark [wal_trafficjam]: 16,200 group sync IOPS                │
│    → Đủ capacity cho 10K+ TPS                                       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.2 WAL Parameters

| Parameter | Value | Reasoning |
|-----------|-------|-----------|
| `wal_compression` | **lz4** | Graviton3 SIMD optimization, 30-50% smaller |
| `wal_buffers` | **64MB** | Large buffer for burst writes |
| `wal_writer_delay` | **10ms** | Flush WAL liên tục, giảm WALWrite lock |
| `wal_writer_flush_after` | **1MB** | Trigger flush mỗi 1MB |

**Tại sao wal_writer_delay = 10ms?**

```
Default: 200ms → WAL flush 5 lần/giây
Tuned:   10ms  → WAL flush 100 lần/giây

Benefit:
  • Giảm WALWrite lock contention
  • WAL được đẩy xuống đĩa đều đặn
  • Tránh dồn cục gây spike latency
```

---

## 5. Checkpoint Configuration

### 5.1 Checkpoint Strategy

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CHECKPOINT STRATEGY (SPARSE)                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Checkpoint = flush tất cả dirty pages ra disk                     │
│                                                                     │
│  Triggers:                                                          │
│    1. WAL size đạt max_wal_size (48GB)                             │
│    2. Thời gian đạt checkpoint_timeout (30 min)                    │
│                                                                     │
│  Tính toán I/O spread:                                              │
│    • Disk write speed: 509 MB/s (from benchmark)                   │
│    • checkpoint_completion_target = 0.9                            │
│    • Spread over: 30min × 0.9 = 27 minutes                        │
│    • Max write rate: 48GB / 27min = 30 MB/s (rất nhẹ nhàng)       │
│                                                                     │
│  Lợi ích:                                                           │
│    • Tránh checkpoint storm                                         │
│    • I/O trải đều, không gây TPS drop                              │
│    • Giảm contention với bgwriter                                  │
│                                                                     │
│  Trade-off:                                                         │
│    • Recovery time tối đa: replay 48GB WAL (~2-3 phút)             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 5.2 Checkpoint Parameters

| Parameter | Value | Reasoning |
|-----------|-------|-----------|
| `checkpoint_timeout` | **30min** | Sparse checkpoint, giảm I/O contention |
| `max_wal_size` | **48GB** | Large buffer cho checkpoint thưa |
| `min_wal_size` | **4GB** | Giữ WAL segments sẵn |
| `checkpoint_completion_target` | **0.9** | Spread writes over 90% of interval |

---

## 6. Background Writer - THE SECRET SAUCE

### 6.1 Vấn đề với Default Config

```
┌─────────────────────────────────────────────────────────────────────┐
│                    BACKEND WRITE STORM                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Default bgwriter:                                                  │
│    bgwriter_delay = 200ms        (5 lần/giây - quá chậm!)          │
│    bgwriter_lru_maxpages = 100   (800KB/round - quá ít!)           │
│    bgwriter_lru_multiplier = 2.0 (reactive thay vì proactive)      │
│                                                                     │
│  Hậu quả:                                                           │
│    • Bgwriter không kịp dọn dirty pages                            │
│    • Backend process tự phải ghi (buffers_backend cao)             │
│    • Backend bị block chờ I/O → TPS drop                           │
│                                                                     │
│  Metric từ pg_stat_bgwriter (before tuning):                       │
│    buffers_backend = 455,969  (63% - RẤT XẤU!)                     │
│    buffers_clean = 31,359     (4% - bgwriter làm quá ít)           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 6.2 Aggressive Bgwriter Tuning

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AGGRESSIVE BGWRITER                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Tuned config:                                                      │
│    bgwriter_delay = 10ms         (100 lần/giây - 20x faster!)      │
│    bgwriter_lru_maxpages = 1000  (8MB/round - 10x more!)           │
│    bgwriter_lru_multiplier = 10.0 (proactive cleaning)             │
│                                                                     │
│  Capacity:                                                          │
│    100 rounds/sec × 1000 pages × 8KB = 800 MB/s                    │
│    (Thực tế không dùng hết, nhưng luôn có clean pages sẵn)        │
│                                                                     │
│  Metric sau tuning:                                                 │
│    buffers_clean = 126,564  (13.6% - gấp 3x!)                      │
│    buffers_backend = reduced → TPS tăng 16%                        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 6.3 Bgwriter Parameters

| Parameter | Default | Tuned | Impact |
|-----------|---------|-------|--------|
| `bgwriter_delay` | 200ms | **10ms** | 100x/sec thay vì 5x/sec |
| `bgwriter_lru_maxpages` | 100 | **1000** | 8MB/round thay vì 800KB |
| `bgwriter_lru_multiplier` | 2.0 | **10.0** | Proactive cleaning |

---

## 7. Group Commit - Bypass fsync Bottleneck

### 7.1 Group Commit Mechanism

```
┌─────────────────────────────────────────────────────────────────────┐
│                    GROUP COMMIT MECHANISM                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  WITHOUT Group Commit (commit_delay = 0):                          │
│  ─────────────────────────────────────────                         │
│    TX1: COMMIT ───► fsync (1.8ms) ───► Done                       │
│    TX2:     COMMIT ───► fsync (1.8ms) ───► Done                   │
│    TX3:         COMMIT ───► fsync (1.8ms) ───► Done               │
│                                                                     │
│    Total: 3 fsyncs × 1.8ms = 5.4ms                                │
│    Throughput: 555 commits/sec (single-thread ceiling)             │
│                                                                     │
│  WITH Group Commit (commit_delay = 50µs):                          │
│  ───────────────────────────────────────                           │
│    TX1: COMMIT ─┐                                                  │
│    TX2: COMMIT ─┼──► (wait 50µs) ──► fsync (1.8ms) ───► All Done │
│    TX3: COMMIT ─┘                                                  │
│                                                                     │
│    Total: 1 fsync × 1.8ms = 1.8ms for 3 commits                   │
│    Effective: 0.6ms per commit (3x faster!)                       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 7.2 Group Commit Parameters

| Parameter | Value | Reasoning |
|-----------|-------|-----------|
| `synchronous_commit` | **on** | Zero data loss (required) |
| `commit_delay` | **50** | 50µs wait = 2.7% of sync time |
| `commit_siblings` | **10** | Only wait if ≥10 concurrent commits |

**Tại sao commit_delay = 50µs?**
- Benchmark: sync latency = 1,850µs (1.85ms)
- 50µs = 2.7% overhead
- Trade-off: +50µs latency, but gom được nhiều TX/fsync
- Net effect: higher throughput

**Tại sao commit_siblings = 10?**
- Target: 10K TPS = 10 TX/ms
- Nếu < 10 concurrent commits → system idle → không đợi
- Nếu ≥ 10 concurrent → system busy → worth waiting

---

## 8. Autovacuum Configuration

### 8.1 Aggressive Autovacuum

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AUTOVACUUM STRATEGY                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Default: autovacuum_vacuum_cost_limit = 200                       │
│    • Vacuum chạy rất chậm (throttled)                              │
│    • Dead tuples tích tụ                                           │
│    • Table bloat → slow queries                                    │
│                                                                     │
│  Benchmark [data_stress]: 18,700 IOPS available                    │
│    • Disk có thừa capacity                                         │
│    • Vacuum có thể chạy nhanh hơn nhiều                            │
│                                                                     │
│  Tuned: autovacuum_vacuum_cost_limit = 10000 (50x default)         │
│    • Vacuum chạy "như bay"                                         │
│    • Dead tuples dọn nhanh                                         │
│    • Table stays lean                                              │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 8.2 Autovacuum Parameters

| Parameter | Value | Reasoning |
|-----------|-------|-----------|
| `autovacuum` | **on** | Always on |
| `autovacuum_max_workers` | **4** | 4 workers cho 8 vCPU |
| `autovacuum_naptime` | **1min** | Check tables mỗi phút |
| `autovacuum_vacuum_scale_factor` | **0.05** | Vacuum khi 5% dead tuples |
| `autovacuum_analyze_scale_factor` | **0.02** | Analyze khi 2% changed |
| `autovacuum_vacuum_cost_limit` | **10000** | 50x default, "thả xích" |

---

## 9. Connection & Parallel Query

### 9.1 Connection Management

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CONNECTION STRATEGY                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Target: 11,500 TPS                                                │
│                                                                     │
│  Nếu mỗi transaction mất 10ms:                                     │
│    Connections needed = 11,500 TPS × 0.010s = 115 connections      │
│                                                                     │
│  Nếu mỗi transaction mất 30ms (complex query):                     │
│    Connections needed = 11,500 TPS × 0.030s = 345 connections      │
│                                                                     │
│  max_connections = 300: đủ cho typical case                        │
│                                                                     │
│  QUAN TRỌNG: Nên dùng connection pooler (PgCat/PgBouncer)          │
│    • Application: 1000+ connections                                │
│    • Pooler → PostgreSQL: 50-100 connections                       │
│    • Reduces context switching overhead                            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 9.2 Parallel Query Parameters

| Parameter | Value | Reasoning |
|-----------|-------|-----------|
| `max_connections` | **300** | Enough for typical OLTP |
| `max_worker_processes` | **8** | Match vCPU count |
| `max_parallel_workers_per_gather` | **4** | Max workers per query |
| `max_parallel_workers` | **8** | Total parallel workers |

---

## 10. Logging Configuration

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `log_min_duration_statement` | **1000** | Log queries > 1s |
| `log_temp_files` | **0** | Log all temp file usage |
| `log_checkpoints` | **on** | Track checkpoint timing |
| `log_lock_waits` | **on** | Detect lock contention |

---

## 11. Full Configuration

```ini
# ==============================================================================
# POSTGRESQL 16 CONFIG: 11.5K TPS ON GRAVITON + RAID10
# ==============================================================================

# --- CONNECTIONS & MEMORY ---
max_connections = 300
shared_buffers = 4GB
work_mem = 32MB
maintenance_work_mem = 1GB
effective_cache_size = 11GB

# --- DISK I/O (Based on FIO benchmarks) ---
random_page_cost = 1.1              # FIO: 0.6ms random latency
seq_page_cost = 1.0
effective_io_concurrency = 200      # RAID10 8 disks

# --- WAL ---
wal_compression = lz4               # Graviton3 SIMD optimization
wal_buffers = 64MB
wal_writer_delay = 10ms             # Flush liên tục
wal_writer_flush_after = 1MB

# --- CHECKPOINT (Sparse) ---
max_wal_size = 48GB
min_wal_size = 4GB
checkpoint_timeout = 30min
checkpoint_completion_target = 0.9

# --- GROUP COMMIT ---
synchronous_commit = on
commit_delay = 50                   # 50µs wait
commit_siblings = 10                # Only wait if ≥10 concurrent

# --- BACKGROUND WRITER (Aggressive) ---
bgwriter_delay = 10ms               # 100x/sec
bgwriter_lru_maxpages = 1000        # 8MB/round
bgwriter_lru_multiplier = 10.0      # Proactive cleaning

# --- AUTOVACUUM (Aggressive) ---
autovacuum = on
autovacuum_max_workers = 4
autovacuum_naptime = 1min
autovacuum_vacuum_scale_factor = 0.05
autovacuum_analyze_scale_factor = 0.02
autovacuum_vacuum_cost_limit = 10000

# --- PARALLEL QUERY ---
max_worker_processes = 8
max_parallel_workers_per_gather = 4
max_parallel_workers = 8

# --- LOGGING ---
log_min_duration_statement = 1000
log_temp_files = 0
log_checkpoints = on
log_lock_waits = on
```

---

## 12. Parameter Impact Summary

### Critical Parameters (Must-have)

| Parameter | Impact | Note |
|-----------|--------|------|
| `bgwriter_delay = 10ms` | **+16% TPS** | Giảm backend write storm |
| `bgwriter_lru_multiplier = 10.0` | **+10% TPS** | Proactive cleaning |
| `commit_delay = 50` | **+5% TPS** | Group commit optimization |

### Important Parameters (Recommended)

| Parameter | Impact | Note |
|-----------|--------|------|
| `wal_writer_delay = 10ms` | Reduce WAL contention | Stable latency |
| `checkpoint_timeout = 30min` | Reduce I/O spikes | Smoother TPS |
| `autovacuum_vacuum_cost_limit = 10000` | Fast vacuum | Less bloat |

### Tuning Order

```
1. bgwriter_delay + bgwriter_lru_multiplier  ← Highest impact
2. commit_delay + commit_siblings            ← Second priority
3. wal_writer_delay                          ← Third priority
4. checkpoint_timeout + max_wal_size         ← Reduce spikes
5. autovacuum tuning                         ← Long-term health
```

---

## 13. Monitoring Queries

```sql
-- Check bgwriter efficiency
SELECT
    buffers_checkpoint,
    buffers_clean,
    buffers_backend,
    round(100.0 * buffers_backend / NULLIF(buffers_alloc, 0), 1) as backend_ratio
FROM pg_stat_bgwriter;
-- Good: backend_ratio < 10%
-- Bad:  backend_ratio > 30%

-- Check checkpoint frequency
SELECT
    checkpoints_timed,
    checkpoints_req,
    checkpoint_write_time,
    checkpoint_sync_time
FROM pg_stat_bgwriter;

-- Check active wait events
SELECT
    wait_event_type,
    wait_event,
    count(*)
FROM pg_stat_activity
WHERE state = 'active'
GROUP BY 1, 2
ORDER BY 3 DESC;

-- Check table bloat
SELECT
    schemaname || '.' || relname as table,
    pg_size_pretty(pg_total_relation_size(relid)) as total_size,
    n_dead_tup,
    round(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 1) as dead_ratio
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 10;
```
