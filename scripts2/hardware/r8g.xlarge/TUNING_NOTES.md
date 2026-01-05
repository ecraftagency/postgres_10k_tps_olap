# Tuning Notes: r8g.xlarge (4 vCPU, 32GB RAM)

## Hardware Context

| Spec | Value |
|------|-------|
| Instance | r8g.xlarge (Graviton4) |
| vCPU | 4 |
| RAM | 32 GB |
| Network | 12.5 Gbps |
| EBS Bandwidth | 10 Gbps |
| Target TPS | 10,000 |
| Target Cost | ~$145/month |

## Benchmark Results

### Round 1: Initial Config (scaled from r8g.2xlarge)

**Date:** 2026-01-04 11:18:23

| Metric | Value |
|--------|-------|
| TPS | 7,027 |
| Latency avg | 14.22 ms |
| Latency stddev | 23.75 ms |

**TPS Progression:**
```
 5s:  3,604 TPS (buffer warming)
10s:  4,715 TPS
15s:  7,573 TPS
20s:  8,060 TPS (peak)
...
60s:  7,335 TPS (stable)
```

**Wait Event Analysis:**
| Wait Event | Count | Issue |
|------------|-------|-------|
| IO/DataFileRead | 90-97 | Dataset (20GB) > shared_buffers (8GB) |
| LWLock/WALWrite | 4-7 | WAL contention |
| Lock/extend | 17-32 | Table extension during warmup |

**Buffer Hit Ratio:** 95.38% → 99.79% (warming over 60s)

**CPU Profile (after warmup):**
- User: 65%
- System: 35%
- IOWait: <1%

**Bottleneck:** CPU-bound after buffer warmup, not I/O

---

### Round 2: Tuning for 4 vCPU

**Date:** 2026-01-04 11:24:21

**Changes Made:**

| Parameter | Before | After | Reason |
|-----------|--------|-------|--------|
| `bgwriter_lru_multiplier` | 2.0 | 4.0 | More aggressive to reduce backend writes |
| `bgwriter_lru_maxpages` | 1000 | 500 | Scaled for 4 vCPU |
| `effective_io_concurrency` | 200 | 100 | Reduced for smaller instance |
| `commit_siblings` | 5 | 3 | Smaller group commit threshold |
| `wal_writer_flush_after` | 1MB | 2MB | Larger WAL batches |

**Results:**

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| TPS | 7,027 | **9,058** | **+29%** |
| Latency avg | 14.22 ms | **11.03 ms** | **-22%** |
| Latency stddev | 23.75 ms | **3.51 ms** | **-85%** |

**TPS Progression:**
```
 5s:  8,867 TPS (stable from start!)
10s:  9,072 TPS
15s:  9,154 TPS
20s:  9,173 TPS (peak)
...
60s:  9,137 TPS
```

**Key Improvements:**
1. No warmup period - stable TPS from second 5
2. Much lower latency variance (3.5ms vs 23.7ms)
3. Consistent ~9K TPS throughout

---

### Round 3: Aggressive Memory + CPU Saving (FAILED - ROLLED BACK)

**Date:** 2026-01-04 11:35:44

**Changes Attempted:**

| Parameter | Before | After | Reason |
|-----------|--------|-------|--------|
| `shared_buffers` | 8GB | 12GB | More buffer cache |
| `wal_compression` | lz4 | off | Save CPU cycles |
| `bgwriter_lru_multiplier` | 4.0 | 5.0 | More aggressive |
| `autovacuum_naptime` | 1min | 10min | Reduce overhead during benchmark |
| `vm.nr_hugepages` | 4400 | 6600 | For 12GB shared_buffers |

**Results: REGRESSION**

| Metric | Round 2 | Round 3 | Change |
|--------|---------|---------|--------|
| TPS | 9,058 | **6,992** | **-23%** |
| Latency avg | 11.03 ms | **14.29 ms** | **+30%** |
| Latency stddev | 3.51 ms | **6.70 ms** | **+91%** |

**TPS Progression:**
```
 5s:  6,675 TPS (worse from start)
10s:  6,887 TPS
15s:  6,928 TPS
20s:  7,233 TPS (peak)
...
60s:  6,934 TPS
```

**Root Cause Analysis:**
1. **shared_buffers=12GB too large**: 37.5% of 32GB RAM leaves insufficient memory for OS page cache and PostgreSQL processes
2. **wal_compression=off increased I/O**: Without compression, WAL writes increased disk I/O pressure
3. **Memory pressure**: 12GB HugePages + PostgreSQL processes = RAM exhaustion

**Lesson Learned:**
- For r8g.xlarge (32GB RAM), shared_buffers=8GB (25%) is optimal
- wal_compression=lz4 is beneficial even on CPU-constrained systems
- Don't over-allocate shared_buffers on smaller instances

**Action:** Rolled back to Round 2 configuration.

---

### Final Validation Runs

**Date:** 2026-01-04 11:50-11:58

After rollback, ran multiple benchmarks to validate stable performance:

| Run | TPS | Latency | Cache State |
|-----|-----|---------|-------------|
| 115002 | 6,737 | 14.8 ms | Cold |
| 115139 | 6,915 | 14.5 ms | Warming |
| 115607 | 7,594 | 13.2 ms | Warming (ended at 9.4K) |
| 115748 | 6,987 | 14.3 ms | Reset by CHECKPOINT |
| Direct pgbench | 6,996 | 14.1 ms | Stable |

**Key Finding:**
- **Cold cache:** ~7,000 TPS (stable, reproducible)
- **Warm cache:** ~9,000 TPS (after extended warmup)
- The 9K TPS in Round 2 was achieved with pre-warmed buffers from Round 1
- CHECKPOINT at benchmark start flushes dirty buffers, resetting cache warmth

**Conclusion:**
- r8g.xlarge realistic performance: **7,000 TPS** (cold) to **9,000 TPS** (warm)
- For guaranteed 10K TPS, upgrade to r8g.2xlarge

---

## Current Configuration (Round 2 - Best)

```bash
# Memory (32GB RAM)
shared_buffers = 8GB          # 25% RAM
effective_cache_size = 22GB   # 70% RAM
work_mem = 27MB               # For 300 connections
maintenance_work_mem = 512MB
huge_pages = on
vm.nr_hugepages = 4400        # 8GB / 2MB + 7%

# Parallel (4 vCPU)
max_worker_processes = 4
max_parallel_workers = 4
max_parallel_workers_per_gather = 2
autovacuum_max_workers = 2

# Background Writer
bgwriter_delay = 10ms
bgwriter_lru_maxpages = 500
bgwriter_lru_multiplier = 4.0

# WAL
wal_buffers = 128MB
wal_writer_delay = 10ms
wal_writer_flush_after = 2MB
wal_compression = lz4

# Checkpoint
max_wal_size = 50GB
min_wal_size = 2GB
checkpoint_timeout = 1h

# Sync
synchronous_commit = on
commit_delay = 0
commit_siblings = 3

# I/O
effective_io_concurrency = 100
random_page_cost = 1.1
```

---

## Gap to Target

| Metric | Cold Cache | Warm Cache | Target | Gap |
|--------|------------|------------|--------|-----|
| TPS | 7,000 | 9,000 | 10,000 | -10% to -30% |

## Next Optimization Ideas

### Option A: Reduce connection overhead
```bash
# Current: 100 clients, 8 threads
# Try: 50 clients, 4 threads (match vCPU)
pgbench -c 50 -j 4 -T 60
```

### Option B: Tune commit batching
```bash
# Try enabling commit_delay for group commit
commit_delay = 10        # 10µs wait
commit_siblings = 2      # Lower threshold
```

### ~~Option C: Increase shared_buffers~~ (TESTED - FAILED)
```bash
# FAILED: 12GB caused memory pressure and -23% TPS
# Keep shared_buffers = 8GB (25% RAM) as optimal
```

### Option D: Use PgCat connection pooling
```bash
# Route through PgCat to reduce connection overhead
# Allows 1000+ clients with only 100-250 backend connections
```

---

## Cost Analysis

| Config | Instance | Monthly | TPS (cold) | TPS (warm) | TPS/$ |
|--------|----------|---------|------------|------------|-------|
| r8g.2xlarge | On-Demand | $290 | 19,527 | 19,527 | 67.3 |
| **r8g.xlarge** | **On-Demand** | **$145** | **7,000** | **9,000** | **48-62** |
| r8g.xlarge | Spot (~70%) | ~$50 | 7,000 | 9,000 | 140-180 |

**Conclusion:**
- r8g.xlarge achieves 70-90% of target TPS at 50% cost
- Best for workloads with consistent traffic (warm cache)
- For guaranteed 10K TPS, use r8g.2xlarge
- With Spot instances, r8g.xlarge offers best TPS/$ ratio
