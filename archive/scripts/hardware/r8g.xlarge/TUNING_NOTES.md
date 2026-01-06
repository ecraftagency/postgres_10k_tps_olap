# Hardware: r8g.xlarge

## Specs

| Component | Spec |
|-----------|------|
| Instance | r8g.xlarge (Memory optimized, Graviton4) |
| vCPU | 4 |
| RAM | 32 GB |
| Network | 12.5 Gbps |
| EBS Bandwidth | 10 Gbps |
| DATA Volume | 8x 50GB gp3 RAID10 (200GB usable) |
| WAL Volume | 8x 30GB gp3 RAID10 (120GB usable) |

## Price

| Instance | vCPU | RAM | On-Demand/mo | Spot/mo |
|----------|------|-----|--------------|---------|
| r8g.2xlarge | 8 | 64GB | $290 | ~$87 |
| **r8g.xlarge** | 4 | 32GB | **$145** | ~$44 |

**Cost Savings: 50%** vs r8g.2xlarge

## Benchmark Results

| Context | TPS (cold) | TPS (warm) | Latency | Report |
|---------|------------|------------|---------|--------|
| r8g.xlarge--tpc-b | 7,000 | 9,000 | 11-14ms | [BENCHMARK.md](../../results/r8g.xlarge--tpc-b/BENCHMARK.md) |

## Key Config (from hardware.env)

```ini
# Memory
VCPU=4
RAM_GB=32

# Scaled for 4 vCPU
shared_buffers = 8GB (25% RAM)
vm.nr_hugepages = 4400
max_parallel_workers = 4
```

## Hardware Limits

| Resource | Limit | At 9K TPS |
|----------|-------|-----------|
| EBS Bandwidth | 1,250 MB/s | ~80 MB/s (6%) |
| Data IOPS | 24,000 | ~0 (cached) |
| WAL IOPS | 24,000 | ~2,500 (10%) |
| CPU | 4 cores | ~100% |

**Bottleneck**: CPU (4 cores saturated at 9K TPS)

## Scaling Notes

- 70-90% of target 10K TPS achieved
- Warm cache critical for 9K TPS
- For guaranteed 10K TPS, upgrade to r8g.2xlarge
