# PostgreSQL 10K+ TPS OLTP on AWS EBS gp3 RAID10

Đạt **11,469 TPS** trên PostgreSQL với chi phí chỉ **$249/tháng** - tiết kiệm 75-90% so với io2 Block Express.

## Key Results

| Metric | Value |
|--------|-------|
| **TPS** | 11,469 |
| **Latency** | 8.70 ms avg |
| **Cost** | $249/month |
| **vs io2** | 75% savings |

```
Tuning Journey:
Baseline     ████████░░░░░░░░░░░░  7,000 TPS
OS Tuned     ████████████░░░░░░░░  9,912 TPS (+41%)
PG Tuned     ████████████████████ 11,469 TPS (+64%)
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    AWS c8g.2xlarge                              │
│                  (8 vCPU, 16GB RAM)                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────────────────┐   ┌─────────────────────────┐    │
│   │      DATA Volume        │   │       WAL Volume        │    │
│   │      RAID10 /data       │   │       RAID10 /wal       │    │
│   ├─────────────────────────┤   ├─────────────────────────┤    │
│   │  8× EBS gp3 (50GB each) │   │  8× EBS gp3 (30GB each) │    │
│   │  Chunk: 64KB            │   │  Chunk: 256KB           │    │
│   │  Purpose: Random I/O    │   │  Purpose: Sequential    │    │
│   └─────────────────────────┘   └─────────────────────────┘    │
│                                                                 │
│   Total: 16 EBS volumes, ~320GB usable                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Provision Infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

terraform init
terraform plan
terraform apply
```

### 2. Setup Server

```bash
# Copy scripts to server
scp -r scripts/ ubuntu@<IP>:~/

# SSH and run setup
ssh ubuntu@<IP>

# Install dependencies
sudo ./scripts/00-deps.sh

# OS tuning
sudo ./scripts/01-os-tuning.sh

# RAID10 setup
sudo ./scripts/02-raid-setup.sh

# Disk tuning
sudo ./scripts/03-disk-tuning.sh

# PostgreSQL installation
sudo ./scripts/05-db-install.sh
```

### 3. Run Benchmarks

```bash
# Disk benchmarks (scenarios 1-10)
sudo python3 scripts/bench.py --run 1   # Sync latency
sudo python3 scripts/bench.py --run 2   # Mixed IOPS
# ... etc

# PostgreSQL benchmark (scenario 11)
sudo python3 scripts/bench.py --run 11  # pgbench TPC-B
```

## Documentation

| Document | Description |
|----------|-------------|
| [MATH.MD](docs/MATH.MD) | Mathematical formulas for all tuning decisions |
| [SYSTEM_CONFIG.MD](docs/SYSTEM_CONFIG.MD) | OS and disk configuration |
| [DB_CONFIG.MD](docs/DB_CONFIG.MD) | PostgreSQL parameter tuning |
| [POSTGRES_BENCHMARK.MD](docs/POSTGRES_BENCHMARK.MD) | Complete case study |
| [DISK_BENCHMARK.MD](docs/DISK_BENCHMARK.MD) | FIO benchmark strategy |

## Key Tuning Parameters

### OS (sysctl)

```bash
vm.dirty_ratio = 4                    # Max 4% RAM dirty (anti-stall)
vm.dirty_background_ratio = 1         # Start flush at 1%
vm.dirty_writeback_centisecs = 100    # Flush every 1s
```

### PostgreSQL

```ini
# Memory
shared_buffers = 4GB
effective_cache_size = 12GB

# Background Writer (THE SECRET SAUCE)
bgwriter_delay = 10ms                 # 100 rounds/sec (not 5)
bgwriter_lru_maxpages = 1000          # 8MB/round capacity
bgwriter_lru_multiplier = 10.0        # Aggressive cleaning

# WAL
wal_buffers = 64MB
max_wal_size = 48GB
checkpoint_timeout = 30min

# Group Commit
commit_delay = 50                     # 50µs wait for batching
commit_siblings = 10
```

## Cost Comparison

| Solution | Monthly Cost | TPS | Cost/TPS |
|----------|-------------|-----|----------|
| **This (RAID10 gp3)** | **$249** | 11,469 | **$0.022** |
| io2 Block Express | $1,002 | ~12,000 | $0.084 |
| **Savings** | **75%** | - | - |

With Spot instances: **$103/month** (90% savings)

## Benchmark Results

### Disk I/O (FIO)

| Scenario | Metric | Result |
|----------|--------|--------|
| Sync Latency | QD1 + fsync | **1.858 ms** |
| Random Read | QD1 | **0.589 ms** |
| Mixed IOPS | 70R:30W | **18,700** |
| Seq Write BW | QD16 | **509 MB/s** |
| Seq Read BW | QD16 | **1,003 MB/s** |

### PostgreSQL (pgbench TPC-B)

| Phase | TPS | Latency | Change |
|-------|-----|---------|--------|
| Baseline | 7,000 | 15 ms | - |
| OS Tuned | 9,912 | 10.05 ms | +41% |
| **PG Tuned** | **11,469** | **8.70 ms** | **+64%** |

## The Math Behind Tuning

Every config value has a mathematical justification:

```
# Why dirty_ratio = 4%?
Max_Dirty = V_disk × T_stall = 509 MB/s × 1s = 509 MB
Ratio = 509 / 16384 × 100 = 3.1% → Choose 4%

# Why bgwriter_delay = 10ms?
V_dirty = 11,500 TPS × 0.1 × 8KB = 9 MB/s
V_clean_default = 100 pages / 0.2s = 4 MB/s → FAIL!
V_clean_tuned = 1000 pages / 0.01s = 800 MB/s → PASS!

# Why can we achieve 11,500 TPS with 1.8ms sync latency?
N_batch = TPS × T_sync / 1000 = 11,469 × 1.858 / 1000 = 21
→ Group commit batches ~21 transactions per fsync!
```

See [MATH.MD](docs/MATH.MD) for complete mathematical derivations.

## Hardware Context System

Configuration is organized by **hardware context** - enabling benchmarks across different hardware configurations.

### Parameter Classification

| Parameter Type | Example | Source |
|---------------|---------|--------|
| **Calculated** | `shared_buffers = 25% RAM` | Hardware specs |
| **Calculated** | `max_parallel_workers = vCPU` | Hardware specs |
| **Calculated** | `effective_io_concurrency` | RAID disk count |
| **Experience-tuned** | `bgwriter_delay = 10ms` | Benchmarking |
| **Experience-tuned** | `commit_delay = 50` | Benchmarking |
| **Experience-tuned** | `vm.dirty_background_ratio = 1` | I/O cliff analysis |

### Naming Convention
```
<instance_type>.<net_gbps>.<ebs_gbps>.<disk_count>disk.<raid_level>
```
Example: `c8gb.2xlarge.33.25.8disk.raid10`

### Generate Config for New Hardware
```bash
cd scripts
./hardware/generate-config.sh r8g.4xlarge 16 8 raid10
# Creates: hardware/r8g.4xlarge.15.10.16disk.raid10/config.env
```

## Project Structure

```
.
├── INFRA.md                    # Infrastructure configuration
├── docs/
│   ├── MATH.MD                 # Mathematical formulas
│   ├── SYSTEM_CONFIG.MD        # OS/disk configuration
│   ├── DB_CONFIG.MD            # PostgreSQL tuning
│   ├── POSTGRES_BENCHMARK.MD   # Case study
│   └── DISK_BENCHMARK.MD       # FIO benchmark guide
├── scripts/
│   ├── hardware/               # Hardware contexts
│   │   ├── _template/          # Config template
│   │   ├── generate-config.sh  # Config generator
│   │   └── c8gb.2xlarge.33.25.8disk.raid10/
│   │       ├── config.env      # Tuning parameters
│   │       ├── proxy/          # PgCat config
│   │       ├── topology.yaml   # Infrastructure spec
│   │       └── TUNING_NOTES.md # Tuning rationale
│   ├── load-config.sh          # Config loader
│   ├── 01-os-tuning.sh         # sysctl, limits
│   ├── 02-raid-setup.sh        # mdadm RAID10
│   ├── 03-disk-tuning.sh       # XFS, read_ahead
│   ├── 05-db-install.sh        # PostgreSQL 16
│   ├── bench.py                # Benchmark runner
│   └── scenarios.json          # Benchmark scenarios
└── terraform/
    ├── main.tf                 # EC2 + EBS
    ├── postgres.tf             # DB instance
    ├── proxy.tf                # PgCat proxy
    └── variables.tf            # Configuration
```

## Requirements

- AWS Account with EC2/EBS access
- Terraform >= 1.0
- Python 3.8+
- Ubuntu 24.04 LTS (ARM64)

## License

MIT

## References

- [PostgreSQL Documentation](https://www.postgresql.org/docs/16/)
- [AWS EBS gp3 Pricing](https://aws.amazon.com/ebs/pricing/)
- [Linux Kernel vm.dirty_ratio](https://www.kernel.org/doc/Documentation/sysctl/vm.txt)
