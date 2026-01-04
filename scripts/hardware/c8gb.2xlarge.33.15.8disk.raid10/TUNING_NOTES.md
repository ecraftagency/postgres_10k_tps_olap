# Tuning Notes: c8gb.2xlarge.33.15.8disk.raid10

## Hardware Specs

| Component | Spec |
|-----------|------|
| Instance | c8gb.2xlarge (Graviton4, Block optimized) |
| vCPU | 8 |
| RAM | 16 GB |
| Network | 33 Gbps |
| EBS Bandwidth | 15 Gbps |
| DATA Volume | 8x 50GB gp3 RAID10 (200GB usable) |
| WAL Volume | 8x 30GB gp3 RAID10 (120GB usable) |

## Benchmark Results

| Metric | Value |
|--------|-------|
| TPS (average) | 11,469 |
| TPS (peak) | 15,553 |
| TPS (minimum) | 6,285 |
| Latency (avg) | 8.70 ms |

## Key Tuning Decisions

### 1. OS Dirty Page Flushing (CRITICAL)

**Problem**: Default Linux settings cause "I/O cliff" - TPS drops 50-70% when dirty pages flush.

**Solution**:
```bash
vm.dirty_background_ratio = 1    # Flush at 1% RAM dirty (~160MB)
vm.dirty_ratio = 4               # Block at 4% (~640MB)
vm.dirty_expire_centisecs = 200  # Data max 2s in RAM
vm.dirty_writeback_centisecs = 100  # Flush every 1s
```

**Result**: I/O cliff severity reduced from 50-70% to 30-40%.

### 2. Background Writer (CRITICAL)

**Problem**: Default bgwriter (200ms delay, 100 pages/round) can't keep up with heavy writes.

**Solution**:
```bash
bgwriter_delay = 10ms           # 100x/sec instead of 5x/sec
bgwriter_lru_maxpages = 1000    # 8MB/round
bgwriter_lru_multiplier = 10.0  # Proactive cleanup
```

**Result**: buffers_clean increased 4x (31K → 126K), TPS stable longer.

### 3. Group Commit (Bypass fsync bottleneck)

**Problem**: EBS fsync latency ~1.8ms limits single-thread commits to ~555 TPS.

**Solution**:
```bash
commit_delay = 50        # Wait 50µs to batch commits
commit_siblings = 10     # Only when ≥10 concurrent commits
```

**Result**: Multiple transactions share one fsync, effective latency reduced.

### 4. Checkpoint Tuning

**Problem**: Frequent checkpoints cause I/O contention with regular writes.

**Solution**:
```bash
checkpoint_timeout = 30min      # Less frequent
max_wal_size = 48GB             # Buffer for sparse checkpoints
checkpoint_completion_target = 0.9  # Spread writes
```

### 5. I/O Concurrency

**Measured** (via fio):
- Random read latency: 0.6ms (excellent for EBS)
- Read IOPS: ~19,000
- Write IOPS: ~12,000

**Settings**:
```bash
random_page_cost = 1.1           # Based on 0.6ms measured latency
effective_io_concurrency = 200   # RAID10 with 8 disks
```

## Values NOT Derived from Hardware

These settings came from benchmarking, not formulas:

| Parameter | Value | Source |
|-----------|-------|--------|
| bgwriter_delay | 10ms | Benchmarking (I/O cliff analysis) |
| bgwriter_lru_multiplier | 10.0 | Benchmarking |
| commit_delay | 50 | Tuned for EBS ~1.8ms latency |
| commit_siblings | 10 | Tuned for workload concurrency |
| vm.dirty_background_ratio | 1 | Benchmarking (I/O cliff analysis) |

## Scaling Notes

If upgrading hardware:

1. **More RAM** (e.g., r8g.2xlarge with 64GB):
   - Increase shared_buffers to 16GB
   - If dataset fits in RAM, expect 2-3x TPS increase

2. **More vCPU**:
   - Increase max_parallel_workers
   - bgwriter settings remain the same

3. **More IOPS** (provision gp3 or use io2):
   - May need to re-tune bgwriter
   - autovacuum_vacuum_cost_limit can increase

## References

- Full benchmark analysis: `docs/POSTGRES_BENCHMARK.MD`
- Disk benchmark results: `docs/DISK_BENCHMARK.MD`
