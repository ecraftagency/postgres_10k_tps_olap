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

## Price/Performance Analysis

| Instance | TPS | Price/mo | TPS/$ | Relative |
|----------|-----|----------|-------|----------|
| c8gb.8xlarge | 40,752 | $833 | 48.9 | 1.0x |
| **r8g.2xlarge** | 17,857 | $290 | **61.6** | **1.26x** |

**Conclusion**: r8g.2xlarge delivers **26% better value** per dollar!

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

**Best Results**: 17,857 TPS avg, 5.5ms latency

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
