# Hardware: r8g.2xlarge

## Specs

| Component | Spec |
|-----------|------|
| Instance | r8g.2xlarge (Memory optimized, Graviton4) |
| vCPU | 8 |
| RAM | 64 GB |
| Network | 15 Gbps |
| EBS Bandwidth | 10 Gbps |
| DATA Volume | 8x 50GB gp3 RAID10 (200GB usable) |
| WAL Volume | 8x 30GB gp3 RAID10 (120GB usable) |

## Price

| Instance | vCPU | RAM | On-Demand/mo | Spot/mo |
|----------|------|-----|--------------|---------|
| c8gb.8xlarge | 32 | 64GB | $833 | ~$250 |
| **r8g.2xlarge** | 8 | 64GB | **$290** | ~$87 |

**Cost Savings: 65%** vs c8gb.8xlarge (same RAM)

## Benchmark Results

| Context | TPS | Latency | Report |
|---------|-----|---------|--------|
| r8g.2xlarge--tpc-b | 19,118 | 5.23ms | [BENCHMARK.md](../../results/r8g.2xlarge--tpc-b/BENCHMARK.md) |

## Key Config (from hardware.env)

```ini
# Memory
VCPU=8
RAM_GB=64

# RAID10 Data (8 disks)
DATA_DISK_COUNT=8
DATA_DISK_SIZE_GB=50
DATA_RAID_CHUNK=64K

# RAID10 WAL (8 disks)
WAL_DISK_COUNT=8
WAL_DISK_SIZE_GB=30
WAL_RAID_CHUNK=256K
```

## Hardware Limits

| Resource | Limit | At 19K TPS |
|----------|-------|------------|
| EBS Bandwidth | 1,250 MB/s | ~160 MB/s (13%) |
| Data IOPS | 24,000 | ~0 (cached) |
| WAL IOPS | 24,000 | ~5,000 (21%) |
| CPU | 8 cores | ~70% |

**Bottleneck**: WAL fsync latency (architectural)
