# Tuning Notes: c8gb.8xlarge.66.50.8disk.raid10

## Hardware Specs

| Component | Spec |
|-----------|------|
| Instance | c8gb.8xlarge (Graviton4, Compute + Block optimized) |
| vCPU | 32 |
| RAM | 64 GB |
| Network | 66 Gbps |
| EBS Bandwidth | 50 Gbps |
| DATA Volume | 8x 50GB gp3 RAID10 (200GB usable) |
| WAL Volume | 8x 30GB gp3 RAID10 (120GB usable) |

## Comparison with c8gb.2xlarge

| Spec | c8gb.8xlarge | c8gb.2xlarge | Improvement |
|------|--------------|--------------|-------------|
| vCPU | 32 | 8 | **4x more** |
| RAM | 64 GB | 16 GB | **4x more** |
| Network | 66 Gbps | 33 Gbps | 2x more |
| EBS BW | 50 Gbps | 25 Gbps | 2x more |
| shared_buffers | 16 GB | 4 GB | 4x more |

---

## Benchmark Journal

### Run 1: Baseline (inherited settings from 2xlarge)
**Date**: 2026-01-04 07:38
**Report**: `results/postgres_tpcb_report_20260104-073809.md`

**Config** (wrong for 32 vCPU):
```
max_worker_processes = 8      # Should be 32
max_parallel_workers = 8      # Should be 32
max_parallel_workers_per_gather = 4
```

**Results**:
| Metric | Value |
|--------|-------|
| TPS avg | 21,199 |
| TPS peak | 34,856 |
| TPS min | 16,570 |
| Latency | 4.69 ms |

**Timeline**:
```
 5s: 34,116 tps (peak)
10s: 34,856 tps (peak)
15s: 26,231 tps <- cliff starts
20s: 18,232 tps
...
60s: 17,296 tps
```

**Observation**: I/O cliff ~50% drop. Worker settings wrong for 32 vCPU.

---

### Run 2: Scenario A (fix parallel workers)
**Date**: 2026-01-04 07:47
**Report**: `results/postgres_tpcb_report_20260104-074742.md`

**Config changes**:
```sql
ALTER SYSTEM SET max_worker_processes = 32;
ALTER SYSTEM SET max_parallel_workers = 32;
ALTER SYSTEM SET max_parallel_workers_per_gather = 8;
-- Restart required
```

**Results**:
| Metric | Baseline | Scenario A | Change |
|--------|----------|------------|--------|
| **TPS avg** | 21,199 | **24,156** | **+14%** |
| TPS peak | 34,856 | 31,093 | -11% |
| TPS min | 16,570 | 17,022 | +3% |
| **Latency** | 4.69 ms | **4.13 ms** | **-12%** |

**Timeline**:
```
 5s: 28,992 tps
10s: 29,636 tps
15s: 30,301 tps
20s: 30,850 tps
25s: 31,093 tps (peak)
30s: 26,973 tps <- cliff starts (later than baseline!)
35s: 20,551 tps
40s: 18,119 tps
45s: 17,023 tps (min)
50s: 20,155 tps
55s: 18,727 tps
60s: 17,352 tps
```

**Observations**:
1. **More stable early performance**: 28-31K range vs baseline's 34K spike
2. **I/O cliff delayed**: Starts at 30s vs 15s in baseline
3. **Higher sustained TPS**: Better average due to stability
4. **Lower peak but better average**: Trade-off worth it

---

### Run 3: Scenario B (shared_buffers = 20GB)
**Date**: 2026-01-04 07:52
**Report**: `results/postgres_tpcb_report_20260104-075211.md`

**Config changes**:
```sql
ALTER SYSTEM SET shared_buffers = '20GB';
ALTER SYSTEM SET bgwriter_lru_maxpages = 1250;  -- Scale for 25% more buffers
-- Restart required
```

**Results**:
| Metric | Scenario A | Scenario B | Change |
|--------|------------|------------|--------|
| **TPS avg** | 24,156 | **31,532** | **+31%** |
| TPS peak | 31,093 | **33,565** | +8% |
| TPS min | 17,022 | **28,743** | +69% |
| **Latency** | 4.13 ms | **~3.0 ms** | **-27%** |

**Timeline** (NO I/O CLIFF! Continuously climbing):
```
 5s: 28,743 tps
10s: 29,699 tps
15s: 30,229 tps
20s: 30,522 tps
25s: 31,014 tps
30s: 31,443 tps
35s: 31,786 tps
40s: 32,225 tps
45s: 32,620 tps
50s: 33,006 tps
55s: 33,319 tps
60s: 33,565 tps  ← Still climbing!
```

**Observations**:
1. **I/O CLIFF ELIMINATED**: No drop throughout 60s test
2. **Continuous improvement**: TPS climbs as caches warm up
3. **Dataset fits in buffer**: 20GB shared_buffers matches ~20GB pgbench data
4. **Minimal variance**: stddev dropped from 3-5ms to 0.5-0.6ms

**Why it works**:
- pgbench scale=1250 ≈ 20GB data
- shared_buffers = 20GB = entire dataset cached
- No disk reads = no read/write contention
- bgwriter only writes, no eviction pressure

---

## Current Best Config (Scenario B)

```ini
# Parallel Query (fixed for 32 vCPU)
max_worker_processes = 32
max_parallel_workers = 32
max_parallel_workers_per_gather = 8

# Memory (optimized for dataset)
shared_buffers = 20GB          # Match dataset size!
effective_cache_size = 45GB
work_mem = 53MB

# Background Writer (scaled for 20GB)
bgwriter_delay = 10ms
bgwriter_lru_maxpages = 1250   # 10MB/round
bgwriter_lru_multiplier = 10.0

# Group Commit (inherited)
commit_delay = 50
commit_siblings = 10
```

**Best Results**: 31,532 TPS avg, 3.0ms latency, NO I/O cliff

## OS Tuning Status

**NOT APPLIED** (AMI defaults):
```
vm.dirty_ratio = 10        # Should be 4
vm.dirty_background_ratio = 5  # Should be 1
```

## Next Experiments

| Scenario | Change | Hypothesis |
|----------|--------|------------|
| ~~B~~ | ~~shared_buffers = 20GB~~ | ✅ **DONE** - I/O cliff eliminated! |
| **C** | shared_buffers = 24GB | Test if extra headroom helps |
| **OS** | Apply dirty_ratio tuning | May not be needed now (no cliff) |

## References

- Cloned from: `c8gb.2xlarge.33.25.8disk.raid10`
