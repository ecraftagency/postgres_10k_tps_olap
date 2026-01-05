# Benchmark Framework Architecture

## Overview

Two-dimensional benchmark framework: `{hardware_context}--{workload_context}`

```
Hardware Context (static)     Workload Context (dynamic)
─────────────────────────     ──────────────────────────
r8g.xlarge                    tpc-b (pgbench OLTP)
r8g.2xlarge                   tpc-c (HammerDB OLTP)
r8g.4xlarge                   tpc-h (HammerDB OLAP)
c8g.2xlarge                   ...future workloads
```

## Directory Structure

```
scripts2/
├── core/                           # Benchmark engine
│   ├── __init__.py
│   ├── bench.py                    # Main entry point
│   ├── diagnostics.py              # System/PG metrics collectors
│   ├── reporter.py                 # Markdown report generator
│   ├── config_loader.py            # Merge hardware + workload configs
│   └── ai_analyzer.py              # Gemini integration
│
├── drivers/                        # Benchmark drivers (pluggable)
│   ├── __init__.py
│   ├── base.py                     # Abstract base class
│   ├── pgbench.py                  # pgbench driver
│   ├── hammerdb.py                 # HammerDB driver
│   └── fio.py                      # fio driver
│
├── hardware/                       # Hardware contexts
│   ├── r8g.xlarge/
│   │   ├── hardware.env            # Instance specs, RAID config
│   │   ├── TUNING_NOTES.md
│   │   └── CALC.MD
│   └── r8g.2xlarge/
│       ├── hardware.env
│       ├── TUNING_NOTES.md
│       └── CALC.MD
│
├── workloads/                      # Workload contexts
│   ├── tpc-b/
│   │   ├── tuning.env              # PG tuning for OLTP light
│   │   ├── scenarios.json          # Benchmark scenarios
│   │   └── schema.sh               # pgbench -i wrapper
│   ├── tpc-c/
│   │   ├── tuning.env              # PG tuning for OLTP heavy
│   │   ├── scenarios.json
│   │   ├── build.tcl               # HammerDB schema builder
│   │   ├── run.tcl                 # HammerDB runner
│   │   └── parser.py               # Parse HammerDB output
│   └── tpc-h/
│       ├── tuning.env              # PG tuning for OLAP (different!)
│       ├── scenarios.json
│       ├── build.tcl
│       ├── run.tcl
│       └── parser.py
│
├── setup/                          # OS/Disk setup (shared)
│   ├── 00-deps.sh
│   ├── 01-os-tuning.sh
│   ├── 02-raid-setup.sh
│   └── 03-disk-tuning.sh
│
├── postgres/                       # PostgreSQL management
│   ├── install.sh                  # Install PG only
│   └── configure.sh                # Apply tuning from workload
│
├── tools/                          # Third-party tool installers
│   ├── install-hammerdb.sh
│   └── install-pgcat.sh
│
└── results/                        # Benchmark results
    ├── r8g.xlarge--tpc-b/
    │   └── 20260105-HHMMSS.md
    ├── r8g.2xlarge--tpc-b/
    │   └── 20260105-HHMMSS.md
    └── r8g.2xlarge--tpc-c/
        └── 20260105-HHMMSS.md
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

```bash
# config_loader.py merges:
# 1. hardware/{instance}/hardware.env  (base)
# 2. workloads/{workload}/tuning.env   (override)
# 3. Derived calculations              (computed)

./core/bench.py --hardware r8g.2xlarge --workload tpc-c --scenario 1
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
    extra_metrics: Dict[str, Any] = field(default_factory=dict)
    raw_output: str = ""
```

### Driver Selection

```python
# core/bench.py
DRIVERS = {
    "tpc-b": "drivers.pgbench.PgbenchDriver",
    "tpc-c": "drivers.hammerdb.HammerDBDriver",
    "tpc-h": "drivers.hammerdb.HammerDBDriver",
    "disk":  "drivers.fio.FioDriver",
}
```

## Diagnostic Engine

Runs in parallel with any benchmark:

```
┌─────────────────────────────────────────────────────────┐
│                  Diagnostic Collectors                   │
├─────────────────────────────────────────────────────────┤
│  iostat -xz 1 {duration}          → Disk I/O metrics    │
│  mpstat -P ALL 1 {duration}       → CPU per-core        │
│  vmstat 1 {duration}              → Memory/swap         │
│  pg_stat_activity                 → Active queries      │
│  pg_stat_bgwriter                 → Buffer/checkpoint   │
│  pg_stat_wal                      → WAL throughput      │
│  pg_wait_events                   → Wait event profile  │
└─────────────────────────────────────────────────────────┘
```

## Results Naming

```
results/{instance}--{workload}/{timestamp}.md

Example:
results/r8g.2xlarge--tpc-c/20260105-103045.md
```

## Workflow

```bash
# 1. Provision infrastructure
cd terraform && terraform apply

# 2. Setup OS and disks (uses hardware.env)
./setup/01-os-tuning.sh --hardware r8g.2xlarge
./setup/02-raid-setup.sh --hardware r8g.2xlarge

# 3. Install and configure PostgreSQL (uses workload tuning.env)
./postgres/install.sh
./postgres/configure.sh --hardware r8g.2xlarge --workload tpc-c

# 4. Build schema
./workloads/tpc-c/schema.sh

# 5. Run benchmark
./core/bench.py --hardware r8g.2xlarge --workload tpc-c --scenario 1

# 6. Results saved to:
# results/r8g.2xlarge--tpc-c/20260105-HHMMSS.md
```

## Migration from v1

```
OLD                                  NEW
───────────────────────────────────  ─────────────────────────────
scripts/hardware/r8g.2xlarge.../     scripts2/hardware/r8g.2xlarge/
  config.env (252 lines)               hardware.env (~50 lines)
                                     scripts2/workloads/tpc-b/
                                       tuning.env (~80 lines)

scripts/bench.py                     scripts2/core/bench.py
                                     scripts2/core/diagnostics.py
                                     scripts2/drivers/pgbench.py

scripts/scenarios.json               scripts2/workloads/tpc-b/scenarios.json
```

## Tool Dependencies

| Tool | Version | Install Location | Purpose |
|------|---------|------------------|---------|
| PostgreSQL | 16.x | apt | Database |
| pgbench | 16.x | apt (with PG) | TPC-B benchmark |
| HammerDB | 4.10 | /opt/HammerDB/ | TPC-C, TPC-H |
| fio | 3.x | apt | Disk benchmark |
| sysstat | latest | apt | iostat, mpstat |
