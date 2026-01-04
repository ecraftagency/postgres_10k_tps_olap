# Tuning Notes: r8g.2xlarge.15.10.8disk.raid10

## Hardware Specs

| Component | Spec |
|-----------|------|
| Instance | r8g.2xlarge (Graviton4, Memory optimized) |
| vCPU | 8 |
| RAM | 64 GB |
| Network | 15 Gbps |
| EBS Bandwidth | 10 Gbps |
| DATA Volume | 8x 50GB gp3 RAID10 (200GB usable) |
| WAL Volume | 8x 30GB gp3 RAID10 (120GB usable) |

## Comparison with c8gb.2xlarge

| Spec | r8g.2xlarge | c8gb.2xlarge | Difference |
|------|-------------|--------------|------------|
| RAM | 64 GB | 16 GB | **4x more** |
| Network | 15 Gbps | 33 Gbps | 2.2x less |
| EBS BW | 10 Gbps | 25 Gbps | 2.5x less |
| shared_buffers | 16 GB | 4 GB | 4x more |
| effective_cache_size | 45 GB | 11 GB | 4x more |

## Hypothesis

With 4x more RAM:
- pgbench dataset (~20GB) fits entirely in shared_buffers + OS cache
- Expect significant TPS improvement from reduced disk reads
- EBS bandwidth may become less critical (fewer reads)
- Checkpoint I/O cliff may be more severe (more dirty pages)

## Benchmark Results

| Metric | Value |
|--------|-------|
| TPS (average) | TBD |
| TPS (peak) | TBD |
| TPS (minimum) | TBD |
| Latency (avg) | TBD |

## Tuning Decisions

### Inherited from c8gb.2xlarge (Experience-Tuned)

These values are kept identical for comparison:

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
```

## Experiment Plan

1. Run baseline pgbench with inherited tuning
2. Compare TPS/latency with c8gb.2xlarge results (11,469 TPS baseline)
3. Analyze if experience-tuned values need adjustment for more RAM
4. Focus areas:
   - Checkpoint behavior (more dirty pages with 16GB shared_buffers)
   - bgwriter effectiveness
   - I/O cliff severity

## References

- Cloned from: `c8gb.2xlarge.33.25.8disk.raid10`
- Full benchmark analysis: `docs/POSTGRES_BENCHMARK.MD`
