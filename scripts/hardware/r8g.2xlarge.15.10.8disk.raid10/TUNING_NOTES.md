# Tuning Notes: r8g.2xlarge.15.10.8disk.raid10

## Hardware Specs

| Component | Spec |
|-----------|------|
| Instance | r8g.2xlarge (Memory optimized, Graviton4) |
| vCPU | 8 |
| RAM | 64 GB |
| Network | 15 Gbps |
| EBS Bandwidth | 10 Gbps |
| DATA Volume | 8x 50GB gp3 RAID10 (200GB usable) |
| WAL Volume | 8x 30GB gp3 RAID10 (120GB usable) |

## Price Comparison

| Instance | vCPU | RAM | On-Demand/mo | Spot/mo |
|----------|------|-----|--------------|---------|
| c8gb.8xlarge | 32 | 64GB | $833 | ~$250 |
| **r8g.2xlarge** | 8 | 64GB | **$290** | ~$87 |

**Cost Savings: 65%** (same RAM, 1/4 vCPUs)

---

## Benchmark Journal

### Run 1: Scenario C Config (from c8gb.8xlarge)
**Date**: 2026-01-04 08:47
**Report**: `results/postgres_tpcb_report_20260104-084729.md`

**Config** (Scenario C scaled for 8 vCPU):
```ini
# Parallel Query (8 vCPU)
max_worker_processes = 8
max_parallel_workers = 8
max_parallel_workers_per_gather = 4

# Memory (with Hugepages)
shared_buffers = 20GB
huge_pages = on

# WAL tuning (from Scenario C)
wal_buffers = 256MB
commit_delay = 0
commit_siblings = 5
max_wal_size = 100GB
checkpoint_timeout = 60min

# Benchmark
pgbench -j 8 -c 100
```

**Results**:
| Metric | Value |
|--------|-------|
| TPS avg | **17,857** |
| TPS peak | 18,824 |
| TPS min | 16,458 |
| Latency | 5.5 ms |

**Timeline**:
```
 5s: 18,003 tps
10s: 18,825 tps (peak)
15s: 18,236 tps
20s: 18,710 tps
25s: 18,713 tps
30s: 18,467 tps
35s: 17,482 tps
40s: 17,490 tps
45s: 17,951 tps
50s: 16,826 tps
55s: 16,457 tps (min)
60s: 17,026 tps
```

**Observations**:
1. Stable performance 16-18K range
2. No I/O cliff (hugepages + dataset cached)
3. Slight decline at end - possible checkpoint activity

---

### Run 2: Warm Cache + Optimized Config
**Date**: 2026-01-04 09:06
**Report**: `results/postgres_tpcb_report_20260104-090604.md`

**Changes from Run 1**:
- Warm cache (dataset fully loaded)
- Same Scenario C config

**Results**:
| Metric | Value | vs Run 1 |
|--------|-------|----------|
| TPS avg | **19,474** | +9.1% |
| TPS peak | 19,723 | |
| TPS min | 19,076 | |
| Latency | 5.15 ms | -6.4% |

**Timeline**:
```
 5s: 19,076 tps
10s: 19,382 tps
15s: 19,389 tps
20s: 19,425 tps
25s: 19,494 tps
30s: 19,473 tps
35s: 19,551 tps
40s: 19,467 tps
45s: 19,406 tps
50s: 19,513 tps
55s: 19,723 tps (peak)
60s: 19,717 tps
```

**pg_deep_stats**:
```
Time      HitRatio  DiskRead  XactCommit  CkptReq  BufBackend  WalBytes
09:06:04  99.84%    0         4           0        0           5.46GB
09:06:09  99.11%    29        14          0        0           5.51GB
...
09:07:00  99.92%    29        134         0        0           6.38GB
```

**Key Insights**:
1. **HitRatio 99.9%** - Dataset hoàn toàn trong RAM
2. **DiskRead = 29** - Gần như 0 disk reads
3. **CkptReq = 0** - Không có checkpoint forced
4. **BufBackend = 0** - BGWriter đang làm tốt
5. **WAL ~920MB/60s** (~15MB/s)

---

### Run 3: Test commit_delay=50 (Group Commit)
**Date**: 2026-01-04 09:01
**Report**: `results/postgres_tpcb_report_20260104-090102.md`

**Changes**:
```ini
commit_delay = 50      # Was 0
commit_siblings = 10   # Was 5
wal_writer_flush_after = 2MB  # Was 1MB
```

**Results**:
| Metric | Value | vs Run 2 |
|--------|-------|----------|
| TPS avg | 16,456 | **-15.5%** ❌ |
| Latency | 6.07 ms | **+17.9%** ❌ |

**Conclusion**: Group commit batching **không hiệu quả** trên EBS gp3.
- EBS latency đã thấp (~2-3ms)
- Chờ thêm 50µs để gom transactions tạo overhead
- **Giữ commit_delay=0** cho production

---

## Price/Performance Analysis

| Instance | TPS | Price/mo | TPS/$ | Relative |
|----------|-----|----------|-------|----------|
| c8gb.8xlarge | 40,752 | $833 | 48.9 | 1.0x |
| **r8g.2xlarge** | 19,474 | $290 | **67.2** | **1.37x** |

**Conclusion**: r8g.2xlarge delivers **37% better value** per dollar!

---

## Current Best Config

### VM Tuning
```bash
vm.nr_hugepages = 11000          # 22GB for PostgreSQL
kernel.sched_autogroup_enabled = 0
```

### PostgreSQL
```ini
# Parallel Query (8 vCPU)
max_worker_processes = 8
max_parallel_workers = 8
max_parallel_workers_per_gather = 4

# Memory (with Hugepages)
shared_buffers = 20GB
huge_pages = on
effective_cache_size = 44GB
work_mem = 54MB

# WAL & Locking
wal_buffers = 256MB
commit_delay = 0
commit_siblings = 5

# Checkpoint & BGWriter
max_wal_size = 100GB
checkpoint_timeout = 60min
bgwriter_delay = 10ms
bgwriter_lru_maxpages = 1000
bgwriter_lru_multiplier = 4.0
```

**Best Results**: 19,474 TPS avg, 5.15ms latency (Run 2)

---

## Recommendation

For workloads requiring:
- **< 15K TPS**: Use r8g.2xlarge (best value)
- **15-35K TPS**: Consider r8g.4xlarge or c8g.4xlarge
- **> 35K TPS**: Use c8gb.8xlarge (raw performance)

---

## References

- Benchmark tool: pgbench TPC-B
- Instance: AWS r8g.2xlarge (Graviton4, Memory optimized)
- Storage: 16x EBS gp3 in RAID10 configuration
