# Benchmark Framework Architecture

## Overview

Three-dimensional benchmark framework: `{topology}/{hardware}--{workload}`

```
Topology (infrastructure)    Hardware (instance)      Workload (benchmark)
─────────────────────────    ─────────────────────    ────────────────────
single-node                  r8g.xlarge               tpc-b (pgbench OLTP)
proxy-single                 r8g.2xlarge              tpc-c (HammerDB OLTP)
primary-replica              r8g.4xlarge              tpc-h (HammerDB OLAP)
htap-full                    c8g.2xlarge              ...future workloads
```

## Context Naming Convention

```
{topology}/{hardware}--{workload}

Examples:
  single-node/r8g.2xlarge--tpc-b
  proxy-single/r8g.4xlarge--tpc-c
  primary-replica/r8g.2xlarge--tpc-h
```

Reports are saved as:
```
results/{topology}/{hardware}--{workload}/{workload}_{timestamp}.md
```

## Directory Structure

```
.
├── terraform/
│   ├── modules/                        # Reusable infrastructure components
│   │   ├── network/                    # VPC, subnets, IGW, routes
│   │   ├── security/                   # Security groups
│   │   ├── postgres-node/              # PostgreSQL EC2 + RAID10 EBS
│   │   └── pgcat-node/                 # Connection pooler
│   │
│   ├── topologies/                     # Infrastructure layouts
│   │   ├── single-node/                # PostgreSQL only
│   │   ├── proxy-single/               # PgCat + PostgreSQL
│   │   └── primary-replica/            # PostgreSQL HA
│   │
│   └── hardware/                       # Instance configurations
│       ├── r8g.xlarge.tfvars           # 4 vCPU, 32GB RAM
│       ├── r8g.2xlarge.tfvars          # 8 vCPU, 64GB RAM
│       ├── r8g.4xlarge.tfvars          # 16 vCPU, 128GB RAM
│       └── c8g.2xlarge.tfvars          # 8 vCPU, 16GB RAM (compute)
│
├── scripts2/
│   ├── core/                           # Benchmark engine
│   │   ├── bench.py                    # Main entry point
│   │   ├── config_loader.py            # Merge hardware + workload configs
│   │   ├── diagnostics.py              # System/PG metrics collectors
│   │   ├── reporter.py                 # Markdown report generator
│   │   ├── verifier.py                 # Config verification
│   │   └── ai_analyzer.py              # Gemini AI analysis
│   │
│   ├── drivers/                        # Benchmark drivers (pluggable)
│   │   ├── base.py                     # Abstract base class
│   │   ├── pgbench.py                  # pgbench TPC-B driver
│   │   ├── hammerdb.py                 # HammerDB TPC-C/H driver
│   │   └── fio.py                      # fio disk benchmark driver
│   │
│   ├── hardware/                       # Hardware contexts
│   │   ├── r8g.xlarge/
│   │   │   └── hardware.env            # Instance specs, RAID config
│   │   └── r8g.2xlarge/
│   │       └── hardware.env
│   │
│   ├── workloads/                      # Workload contexts
│   │   ├── tpc-b/
│   │   │   ├── tuning.env              # PG tuning for OLTP light
│   │   │   └── scenarios.json
│   │   ├── tpc-c/
│   │   │   └── tuning.env              # PG tuning for OLTP heavy
│   │   └── tpc-h/
│   │       └── tuning.env              # PG tuning for OLAP
│   │
│   ├── setup/                          # OS/Disk setup (shared)
│   │   ├── 00-deps.sh
│   │   ├── 01-os-tuning.sh
│   │   ├── 02-raid-setup.sh
│   │   └── 03-disk-tuning.sh
│   │
│   ├── postgres/                       # PostgreSQL management
│   │   ├── install.sh
│   │   └── configure.sh
│   │
│   └── results/                        # Benchmark reports
│       └── {topology}/{hardware}--{workload}/
│           └── {workload}_{timestamp}.md
│
└── docs2/                              # Documentation
    ├── ARCHITECTURE.md                 # This file
    ├── QUICKSTART.md                   # Getting started
    ├── BENCHMARKING.md                 # Running benchmarks
    ├── CONFIGURATION.md                # Parameter reference
    └── TUNING.md                       # Tuning rationale
```

## Terraform Architecture

### Module Design

```
┌─────────────────────────────────────────────────────────────┐
│                        Topology                              │
│   (single-node, proxy-single, primary-replica, htap-full)   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  ┌─────────┐ │
│  │ network  │  │ security │  │ postgres-node │  │ pgcat-  │ │
│  │ module   │  │ module   │  │    module     │  │  node   │ │
│  └──────────┘  └──────────┘  └──────────────┘  └─────────┘ │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                    Hardware Config                           │
│        (r8g.xlarge.tfvars, r8g.2xlarge.tfvars, ...)        │
└─────────────────────────────────────────────────────────────┘
```

### Topologies

| Topology | Components | Use Case |
|----------|------------|----------|
| `single-node` | PostgreSQL only | Development, baseline testing |
| `proxy-single` | PgCat + PostgreSQL | Connection pooling tests |
| `primary-replica` | PostgreSQL HA | Replication tests |
| `htap-full` | Proxy + Primary + Replica + ClickHouse | Full HTAP workload |

### Usage Pattern

```bash
cd terraform/topologies/single-node
terraform init
terraform apply \
  -var="aws_profile=your-profile" \
  -var="key_name=your-key" \
  -var="postgres_ami=ami-xxx" \
  -var-file=../../hardware/r8g.2xlarge.tfvars
```

## Config System

### Layer 1: Hardware Context (`hardware.env`)

Static hardware specifications:

```bash
# Instance
INSTANCE_TYPE="r8g.2xlarge"
VCPU=8
RAM_GB=64
NETWORK_GBPS=15
EBS_GBPS=10

# RAID - Data
DATA_MOUNT="/data"
DATA_DISK_COUNT=8
DATA_DISK_SIZE_GB=50
DATA_RAID_LEVEL=10
DATA_RAID_CHUNK="64K"

# RAID - WAL
WAL_MOUNT="/wal"
WAL_DISK_COUNT=8
WAL_DISK_SIZE_GB=30
WAL_RAID_LEVEL=10
WAL_RAID_CHUNK="256K"

# OS Tuning (hardware-dependent)
VM_SWAPPINESS=1
VM_NR_HUGEPAGES=11000
VM_MIN_FREE_KBYTES=671088
```

### Layer 2: Workload Context (`tuning.env`)

Workload-specific PostgreSQL tuning:

```bash
# TPC-B/TPC-C (OLTP)
PG_SHARED_BUFFERS="20GB"
PG_WORK_MEM="54MB"
PG_EFFECTIVE_CACHE_SIZE="44GB"
PG_MAX_PARALLEL_WORKERS=4
PG_JIT="off"

# TPC-H (OLAP) - DIFFERENT!
PG_SHARED_BUFFERS="16GB"
PG_WORK_MEM="512MB"           # 10x higher
PG_EFFECTIVE_CACHE_SIZE="48GB"
PG_MAX_PARALLEL_WORKERS=8     # Full parallel
PG_JIT="on"                   # JIT for complex queries
```

### Config Loading

```python
# config_loader.py merges:
# 1. hardware/{hardware}/hardware.env  (base)
# 2. workloads/{workload}/tuning.env   (override)
# 3. Derived calculations              (computed)
```

## Benchmark Drivers

### Interface Contract

All drivers must return `BenchmarkResult`:

```python
@dataclass
class BenchmarkResult:
    name: str                    # "TPC-B", "TPC-C", "TPC-H"
    primary_metric: float        # Main result value
    primary_metric_unit: str     # "TPS", "NOPM", "QphH"
    duration_seconds: int
    latency_avg_ms: float
    latency_p99_ms: float
    latency_stddev_ms: float
    total_transactions: int
    failed_transactions: int
    extra_metrics: Dict[str, Any]
    raw_output: str
```

### Driver Selection

```python
DRIVERS = {
    "tpc-b": PgbenchDriver,
    "tpc-c": HammerDBDriver,  # TODO
    "tpc-h": HammerDBDriver,  # TODO
}
```

## Diagnostic Engine

Runs in parallel with any benchmark:

```
┌─────────────────────────────────────────────────────────────┐
│                  Diagnostic Collectors                       │
├─────────────────────────────────────────────────────────────┤
│  iostat -xz 1 {duration}          → Disk I/O metrics        │
│  mpstat -P ALL 1 {duration}       → CPU per-core            │
│  vmstat 1 {duration}              → Memory/swap             │
│  pg_stat_activity                 → Active queries          │
│  pg_stat_bgwriter                 → Buffer/checkpoint       │
│  pg_stat_wal                      → WAL throughput          │
│  pg_wait_events                   → Wait event profile      │
└─────────────────────────────────────────────────────────────┘
```

## Config Verification

Before each benchmark, the framework verifies actual settings match expected:

```
┌──────────────────────────────────────────────────────────────┐
│                    Config Verification                        │
├──────────────────────────────────────────────────────────────┤
│ Category        │ Setting              │ Expected │ Actual   │
├─────────────────┼──────────────────────┼──────────┼──────────┤
│ PostgreSQL      │ shared_buffers       │ 20GB     │ 20GB  ✓  │
│ PostgreSQL      │ wal_buffers          │ 256MB    │ 256MB ✓  │
│ OS              │ vm.nr_hugepages      │ 11000    │ 11000 ✓  │
│ Disk            │ /dev/md0 read_ahead  │ 2048     │ 2048  ✓  │
└──────────────────────────────────────────────────────────────┘
```

## Workflow

```bash
# 1. Deploy infrastructure
cd terraform/topologies/single-node
terraform apply -var-file=../../hardware/r8g.2xlarge.tfvars

# 2. Sync scripts
rsync -avz scripts2/ ubuntu@<IP>:~/scripts2/

# 3. Setup OS and disks
ssh ubuntu@<IP>
sudo ./scripts2/setup/01-os-tuning.sh
sudo ./scripts2/setup/02-raid-setup.sh

# 4. Install and configure PostgreSQL
sudo ./scripts2/postgres/install.sh
sudo ./scripts2/postgres/configure.sh --hardware r8g.2xlarge --workload tpc-b

# 5. Run benchmark
sudo python3 scripts2/core/bench.py \
  --topology single-node \
  --hardware r8g.2xlarge \
  --workload tpc-b \
  --duration 60 \
  --clients 100

# 6. Results saved to:
# results/single-node/r8g.2xlarge--tpc-b/tpc-b_20260105-HHMMSS.md
```

## Tool Dependencies

| Tool | Version | Purpose |
|------|---------|---------|
| PostgreSQL | 16.x | Database |
| pgbench | 16.x | TPC-B benchmark |
| HammerDB | 4.10 | TPC-C, TPC-H |
| fio | 3.x | Disk benchmark |
| sysstat | latest | iostat, mpstat |
