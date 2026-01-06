# PostgreSQL Benchmark Framework v2

## Design Principles

- **KISS**: 2 dimensions only (Topology × Scenario)
- **Fixed Hardware**: Optimize for benchmark, not production
- **Dynamic Config**: Auto-detect hardware, calculate optimal settings
- **Fast Iteration**: init → baseline → optimize → ceiling

---

## Infrastructure (Fixed)

### DB Nodes (r8g.xlarge)

| Spec | Value |
|------|-------|
| Instance | r8g.xlarge |
| vCPU | 4 |
| RAM | 32GB |
| Network | 12.5 Gbps |

**Storage (RAID0 for performance):**

| Volume | Config |
|--------|--------|
| DATA | 4× 50GB gp3, RAID0, 3000 IOPS, 125MB/s each |
| WAL | 4× 30GB gp3, RAID0, 3000 IOPS, 125MB/s each |

### Proxy Node (c8g.xlarge)

| Spec | Value |
|------|-------|
| Instance | c8g.xlarge |
| vCPU | 4 |
| RAM | 8GB |
| Storage | 1× 30GB gp3, 3000 IOPS, 125MB/s |

---

## Dimensions

### Dimension 1: Topologies (4 fixed)

```
┌──────────────────────────────────────────────────────────────────┐
│ 1. single-node                                                    │
│    [DB r8g.xlarge] ◄────────────────────────── Benchmark          │
├──────────────────────────────────────────────────────────────────┤
│ 2. proxy-single                                                   │
│    [DB r8g.xlarge] ◄── [Proxy c8g.xlarge] ◄─── Benchmark          │
├──────────────────────────────────────────────────────────────────┤
│ 3. primary-replica                                                │
│    [Primary r8g.xlarge] ──► [Replica r8g.xlarge]                  │
│           │                        │                              │
│           └─► OLTP                 └─► OLAP                       │
├──────────────────────────────────────────────────────────────────┤
│ 4. primary-replica-proxy                                          │
│    [Primary] ──────► [Replica]                                    │
│        │                  │                                       │
│        └─► [Proxy c8g.xlarge] ◄──────────────── Benchmark         │
│            (read/write routing)                                   │
└──────────────────────────────────────────────────────────────────┘
```

### Dimension 2: Scenarios (18 fixed) - 100% IDENTICAL to v1

**Source:** `archive/scripts/scenarios.json` (MUST NOT CHANGE)

| ID | id (internal) | name | desc | target |
|----|---------------|------|------|--------|
| **FIO Disk I/O (1-10)** |||||
| 1 | `wal_heartbeat` | The Heartbeat | Commit Latency - Single backend sync write (QD1+fdatasync) | wal |
| 2 | `data_stress` | Stress Test | Mixed IOPS - Random R/W 70:30 at saturation (QD64x4) | data |
| 3 | `data_latency` | Latency | Single Thread Random Read - True EBS latency (QD1) | data |
| 4 | `data_throughput` | Throughput | Sequential Read - Max bandwidth (1MB blocks, QD16) | data |
| 5 | `wal_firehose` | The Firehose | Sequential Throughput - Max write bandwidth (1MB, no fsync) | wal |
| 6 | `wal_trafficjam` | The Traffic Jam | Group Commit Stress - Multi-thread sync write (QD32x4+fdatasync) | wal |
| 7 | `data_seq_write` | Sequential Write | Checkpoint-style - Large sequential writes (1MB blocks, QD16) | data |
| 8 | `data_rand_write` | Random Write | Pure Write IOPS - Random writes only (8K blocks, QD64x4) | data |
| 9 | `data_mixed_sync` | Mixed Sync | DB-Realistic - Random R/W 70:30 with fdatasync (QD32x4) | data |
| 10 | `wal_replay` | Recovery Replay | Sequential Read - Simulates Replica Catch-up or Crash Recovery | wal |
| **pgbench (11-14)** |||||
| 11 | `postgres_tpcb` | TPC-B Write Intensive | Standard OLTP Benchmark - pgbench {clients} clients | postgres |
| 12 | `postgres_pure_read` | Pure Read | SELECT-only - Tests RAM throughput (pgbench -S) | postgres |
| 13 | `postgres_connection_storm` | Connection Storm | Connect per transaction - Tests auth overhead (pgbench -C) | postgres |
| 14 | `postgres_high_concurrency` | High Concurrency | High concurrency stress test - {clients} clients | postgres |
| **sysbench (15-18)** |||||
| 15 | `sysbench_oltp_read` | OLTP Read Only | Sysbench oltp_read_only - Pure SELECT workload | postgres |
| 16 | `sysbench_oltp_rw` | OLTP Read/Write | Sysbench oltp_read_write - Mixed transactions | postgres |
| 17 | `sysbench_oltp_write` | OLTP Write Only | Sysbench oltp_write_only - INSERT/UPDATE/DELETE | postgres |
| 18 | `sysbench_oltp_point` | OLTP Point Select | Sysbench oltp_point_select - Simple PK lookups | postgres |

**CRITICAL:** `scenarios.json` sẽ copy nguyên xi từ `archive/scripts/scenarios.json`
- Chỉ thay đổi: `disks.data.volumes`, `disks.wal.volumes` (md0, md1 thay vì list nvme)
- Commands begin/parallel/end: KHÔNG THAY ĐỔI
- Output format: KHÔNG THAY ĐỔI

### Compatibility Matrix

| Scenario | single-node | proxy-single | primary-replica | primary-replica-proxy |
|----------|-------------|--------------|-----------------|----------------------|
| 1-10 (fio) | ✓ | ✓ (on DB) | ✓ (on both) | ✓ (on both) |
| 11-14 (pgbench) | ✓ | ✓ | ✓ (primary) | ✓ |
| 15-18 (sysbench) | ✓ | ✓ | ✓ (primary) | ✓ |

---

## Directory Structure

```
.
├── terraform/
│   ├── modules/
│   │   ├── network/              # VPC, subnets, IGW
│   │   ├── security/             # Security groups
│   │   ├── db-node/              # r8g.xlarge + RAID0
│   │   └── proxy-node/           # c8g.xlarge + single vol
│   │
│   └── topologies/
│       ├── single-node/
│       ├── proxy-single/
│       ├── primary-replica/
│       └── primary-replica-proxy/
│
├── scripts/
│   ├── setup/
│   │   ├── 00-deps.sh            # fio, sysbench, sysstat, etc.
│   │   ├── 01-os-tuning.sh       # sysctl, limits
│   │   ├── 02-raid-setup.sh      # RAID0 assembly
│   │   ├── 03-disk-tuning.sh     # scheduler, read_ahead
│   │   ├── 04-postgres.sh        # Install PG 16
│   │   └── 05-proxy.sh           # Install PgCat (proxy only)
│   │
│   ├── config/
│   │   ├── baseline.env          # Base config template
│   │   └── calculate.py          # Dynamic config from hardware
│   │
│   ├── scenarios.json            # All 18 scenarios
│   │
│   ├── bench.py                  # Main entry: bench.py <scenario_id>
│   │
│   ├── tools/
│   │   ├── verify-config.sh
│   │   ├── collect-facts.sh      # Hardware detection
│   │   └── report.py             # Generate markdown report
│   │
│   └── results/
│       └── {topology}_{scenario}_{timestamp}.md
│
├── docs/
│   ├── ARCHITECTURE-V2.md        # This file
│   ├── QUICKSTART.md
│   └── ...
│
└── archive/                      # Old v1 code backup
```

---

## CLI

```bash
# Deploy infrastructure
cd terraform/topologies/single-node
terraform apply

# Setup server (run once per topology)
./scripts/setup/00-deps.sh
./scripts/setup/01-os-tuning.sh
./scripts/setup/02-raid-setup.sh
./scripts/setup/03-disk-tuning.sh
./scripts/setup/04-postgres.sh

# Run benchmark (just scenario ID)
python3 scripts/bench.py 11

# Output: results/single-node_11_20260106-143000.md
```

---

## Dynamic Config Calculation

```python
# scripts/config/calculate.py

def calculate_config():
    # Auto-detect hardware
    vcpu = detect_vcpu()        # 4 for r8g.xlarge
    ram_gb = detect_ram()       # 32 for r8g.xlarge

    # Calculate PostgreSQL config
    return {
        'shared_buffers': f"{int(ram_gb * 0.25)}GB",      # 8GB
        'effective_cache_size': f"{int(ram_gb * 0.70)}GB", # 22GB
        'work_mem': f"{int(ram_gb * 1024 / 100)}MB",       # 320MB
        'max_connections': vcpu * 100,                     # 400
        'max_worker_processes': vcpu,                      # 4
        'max_parallel_workers': vcpu,                      # 4
        'max_parallel_workers_per_gather': vcpu // 2,      # 2
        'autovacuum_max_workers': max(2, vcpu // 2),       # 2
    }
```

---

## Benchmark Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. INIT CONFIG                                               │
│    - Auto-detect topology (check proxy/replica)              │
│    - Auto-detect hardware (vCPU, RAM)                        │
│    - Calculate baseline PostgreSQL config                    │
├─────────────────────────────────────────────────────────────┤
│ 2. BASELINE FACT BENCH                                       │
│    - Run disk I/O scenarios (1-10) → get IOPS/throughput     │
│    - Run quick TPC-B (11) → get baseline TPS                 │
│    - Document current performance                            │
├─────────────────────────────────────────────────────────────┤
│ 3. OPTIMIZATION ROUNDS                                       │
│    - Tune one parameter at a time                            │
│    - Re-run relevant scenario                                │
│    - Compare with baseline                                   │
│    - Keep or revert                                          │
├─────────────────────────────────────────────────────────────┤
│ 4. CEILING CALCULATION                                       │
│    - Run full sustained benchmark (12)                       │
│    - Run high connection test (13)                           │
│    - Document max achievable performance                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Result Format

**Filename:** `{topology}_{scenario_id}_{timestamp}.md`

**Content:**
```markdown
# Benchmark Report

## Context
- **Topology:** single-node
- **Scenario:** 11 (tpc-b-quick)
- **Timestamp:** 2026-01-06 14:30:00

## Hardware (auto-detected)
- **Instance:** r8g.xlarge
- **vCPU:** 4
- **RAM:** 32GB
- **DATA:** /dev/md0 (4x50GB RAID0)
- **WAL:** /dev/md1 (4x30GB RAID0)

## PostgreSQL Config (calculated)
| Parameter | Value |
|-----------|-------|
| shared_buffers | 8GB |
| effective_cache_size | 22GB |
| max_connections | 400 |

## Results
| Metric | Value |
|--------|-------|
| **TPS** | 12,345 |
| Duration | 60s |
| Avg Latency | 8.1ms |
| P99 Latency | 15.2ms |

## Diagnostics
- iostat output
- mpstat output
- pg_stat_* snapshots
```

---

## Implementation Tasks

### Phase 1: Terraform (Infrastructure)

- [ ] **T1.1** Create `modules/db-node/` (r8g.xlarge + RAID0 setup)
- [ ] **T1.2** Create `modules/proxy-node/` (c8g.xlarge + single vol)
- [ ] **T1.3** Create `modules/network/` (VPC, subnets)
- [ ] **T1.4** Create `modules/security/` (security groups)
- [ ] **T1.5** Create `topologies/single-node/`
- [ ] **T1.6** Create `topologies/proxy-single/`
- [ ] **T1.7** Create `topologies/primary-replica/`
- [ ] **T1.8** Create `topologies/primary-replica-proxy/`

### Phase 2: Scripts (Setup)

- [ ] **S2.1** Create `setup/00-deps.sh` (fio, sysbench, sysstat, iostat, mpstat)
- [ ] **S2.2** Create `setup/01-os-tuning.sh` (sysctl, limits, hugepages)
- [ ] **S2.3** Create `setup/02-raid-setup.sh` (RAID0 for data + wal)
- [ ] **S2.4** Create `setup/03-disk-tuning.sh` (scheduler, read_ahead)
- [ ] **S2.5** Create `setup/04-postgres.sh` (install PG 16)
- [ ] **S2.6** Create `setup/05-proxy.sh` (install PgCat)

### Phase 3: Scripts (Config)

- [ ] **S3.1** Create `config/calculate.py` (dynamic config from hardware)
- [ ] **S3.2** Create `config/baseline.env` (template)
- [ ] **S3.3** Create `tools/collect-facts.sh` (hardware detection)
- [ ] **S3.4** Create `tools/verify-config.sh` (validate settings)

### Phase 4: Scripts (Benchmark)

- [ ] **S4.1** Copy `scenarios.json` from `archive/scripts/scenarios.json` (100% identical, only change disk config)
- [ ] **S4.2** Create `bench.py` (main entry point - simplified from v1)
- [ ] **S4.3** Verify scenarios 1-10 (fio) output matches v1 exactly
- [ ] **S4.4** Verify scenarios 11-14 (pgbench) output matches v1 exactly
- [ ] **S4.5** Verify scenarios 15-18 (sysbench) output matches v1 exactly
- [ ] **S4.6** Create `tools/report.py` (markdown generation - same format as v1)

### Phase 5: Documentation

- [ ] **D5.1** Update `README.md`
- [ ] **D5.2** Update `docs/QUICKSTART.md`
- [ ] **D5.3** Update `docs/CONFIGURATION.md`

### Phase 6: Testing

- [ ] **X6.1** Test single-node topology deploy + scenario 1-14
- [ ] **X6.2** Test proxy-single topology deploy + all scenarios
- [ ] **X6.3** Test primary-replica topology deploy
- [ ] **X6.4** Test primary-replica-proxy topology deploy

---

## Quick Reference

```bash
# Deploy
cd terraform/topologies/single-node && terraform apply

# Setup
./scripts/setup/00-deps.sh && \
./scripts/setup/01-os-tuning.sh && \
./scripts/setup/02-raid-setup.sh && \
./scripts/setup/03-disk-tuning.sh && \
./scripts/setup/04-postgres.sh

# Benchmark
python3 scripts/bench.py 11      # TPC-B quick
python3 scripts/bench.py 1-10    # All disk I/O
python3 scripts/bench.py 11-18   # All DB benchmarks
```
