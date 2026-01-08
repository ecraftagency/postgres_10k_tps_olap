# PostgreSQL Benchmark Framework

## Principles

- **KISS**: Fixed hardware, proven configs, reproducible results
- **Golden Facts**: Proven configs that hit hardware ceiling (Topology × Workload)
- **Config Source of Truth**: `scripts/config/*.env` → applied to instance → verified by benchmark

## Directory Structure

```
.
├── terraform/
│   ├── modules/
│   │   ├── network/           # VPC, subnets
│   │   └── db-node/           # EC2 + EBS
│   └── topologies/
│       ├── proxy-primary/     # Current: proxy + primary
│       └── (future)           # primary-replica, etc.
│
├── scripts/
│   ├── config/                # Source of truth for configs
│   │   ├── os.env             # OS sysctl (memory, TCP, kernel)
│   │   ├── base.env           # Disk/RAID config
│   │   └── primary.env        # PostgreSQL config
│   │
│   ├── services/              # Systemd units
│   │   ├── postgresql.service
│   │   ├── disable-thp.service
│   │   └── block-tuning.service
│   │
│   ├── scenarios.json         # Benchmark definitions (1-13)
│   ├── bench.py               # Benchmark runner
│   └── verify-config.sh       # Config verification
│
├── golden-facts/              # Flat: single markdown per Topology×Workload
│   └── {Topology}x{Workload}-{MMDDYY}.md
│
├── results/                   # Flat: benchmark result markdown
│   └── {scenario_id}-{YYYYMMDD-HHMMSS}.md
│
└── docs/
    ├── ARCHITECTURE.md        # This file
    └── RESULT-STRUCTURE.md    # Result format spec
```

## Hardware (Fixed)

| Node | Instance | vCPU | RAM | Storage |
|------|----------|------|-----|---------|
| Primary | r8g.xlarge | 4 | 32GB | 4x gp3 DATA + 4x gp3 WAL (RAID0) |
| Proxy | c8g.xlarge | 4 | 8GB | Benchmark driver |

## IP Convention

```
10.0.1.10  primary (db)
10.0.1.11  replica (future)
10.0.1.20  proxy
```

## Scenarios

| ID | Name | Type |
|----|------|------|
| 1-10 | FIO disk tests | Disk I/O |
| 11 | postgres_tpcb | TPC-B standard |
| 12 | postgres_pure_read | SELECT-only (-S) |
| 13 | postgres_connection_storm | Connect per txn (-C) |
| 14 | postgres_high_concurrency | 200 clients stress |
| 15 | postgres_tpcb_prepared | TPC-B prepared (-M prepared) |

## Workflow

```
1. terraform apply          → provision infrastructure
2. verify-config.sh         → confirm 52 configs match
3. bench.py 12              → run benchmark, output result markdown
4. results/*.md             → contains all data + Golden Fact Template
5. baking agent             → reads result, produces golden-facts/*.md
```

## File Formats

| Directory | Format | Example |
|-----------|--------|---------|
| scripts/config/ | .env files | os.env, base.env, primary.env |
| results/ | Single markdown | postgres_tpcb_prepared-20260108-095846.md |
| golden-facts/ | Single markdown | PrimaryxOLTP-010826.md |

## Golden Fact Criteria

A config becomes a golden fact when:
- CPU ≥ 90% OR disk util ≥ 80% (ceiling hit)
- 3 runs with < 5% variance
- Little's Law verified: TPS ≈ clients / latency

## Current Ceiling

**12,461 TPS** on r8g.xlarge (3,115 TPS/Core)

Bottleneck: DATA disk util ~100%, WAL disk util ~90% (EBS gp3 IOPS limit)
