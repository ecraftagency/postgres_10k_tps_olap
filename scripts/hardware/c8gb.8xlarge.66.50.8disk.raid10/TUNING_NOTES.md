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

## Benchmark Results

| Metric | c8gb.8xlarge | c8gb.2xlarge | Improvement |
|--------|--------------|--------------|-------------|
| **TPS (average)** | **21,199** | 11,469 | **+85%** |
| **TPS (peak)** | **34,856** | 15,553 | **+124%** |
| TPS (minimum) | 16,570 | 6,285 | +164% |
| **Latency (avg)** | **4.69 ms** | 8.70 ms | **-46%** |

## Key Observations

### 1. I/O Cliff Still Present
```
progress:  5.0 s, 34115.7 tps  (peak)
progress: 10.0 s, 34856.4 tps  (peak)
progress: 15.0 s, 26230.6 tps  <- cliff starts
progress: 20.0 s, 18231.6 tps  <- stabilizes lower
progress: 25.0 s, 16569.8 tps
...
progress: 60.0 s, 17296.0 tps
```

Drop from 34K to 17K TPS (~50%) when dirty pages flush. Same pattern as 2xlarge.

### 2. OS Tuning NOT Applied (AMI defaults)
```
vm.dirty_ratio = 10        # Should be 4
vm.dirty_background_ratio = 5  # Should be 1
```

**Potential improvement**: Apply OS tuning could reduce I/O cliff severity.

### 3. Dataset Fits in Memory
- pgbench scale=1250 (~20GB data)
- shared_buffers = 16GB + OS cache
- Most reads served from memory → explains 85% TPS increase

## Tuning Decisions

### Inherited from c8gb.2xlarge (Experience-Tuned)

```bash
# OS - Prevent I/O cliff
vm.dirty_background_ratio = 1
vm.dirty_ratio = 4
vm.dirty_expire_centisecs = 200
vm.dirty_writeback_centisecs = 100

# PostgreSQL - Background Writer
bgwriter_delay = 10ms
bgwriter_lru_maxpages = 1000
bgwriter_lru_multiplier = 10.0

# PostgreSQL - Group Commit
commit_delay = 50
commit_siblings = 10
```

### Calculated for 64GB RAM

```bash
shared_buffers = 16GB       # 25% of 64GB
effective_cache_size = 45GB # 70% of 64GB
maintenance_work_mem = 4GB  # 64GB / 16
work_mem = 53MB             # 64GB / 300 / 4
max_parallel_workers = 32   # Match vCPU
```

## Next Steps

1. Apply OS tuning (01-os-tuning.sh) and re-benchmark
2. With proper dirty_ratio=4, expect I/O cliff to reduce from 50% to 30-40%
3. Consider increasing bgwriter_lru_maxpages for 16GB shared_buffers

## References

- Cloned from: `c8gb.2xlarge.33.25.8disk.raid10`
- Full benchmark analysis: `docs/POSTGRES_BENCHMARK.MD`
