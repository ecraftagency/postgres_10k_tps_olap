# Benchmark Result Structure

## Overview

Result markdown is the **complete package** for golden fact baking:
- Full benchmark environment context (runner + target specs)
- Scenario details (name, description, dataset, scale factor)
- Workload parameters (clients, threads, duration, all flags)
- All benchmark data (raw output, diagnostics)
- All 52 configs grouped by category
- Golden Fact Template (exact format for baking agent)

Any agent reading a result markdown should have **all information needed** to:
1. Understand the test environment
2. Reproduce the benchmark
3. Analyze the results
4. Bake a golden fact

## File Location & Naming

```
results/{scenario_id}-{YYYYMMDD}-{HHMMSS}.md
```

---

## Result Markdown Sections

### 1. Header

```markdown
# Benchmark Report: {scenario_name}

**Date:** YYYY-MM-DD HH:MM:SS
**Scenario ID:** {scenario_id}
**Topology:** primary | replica | standalone
**Workload:** oltp | olap | mixed

> **Golden Fact Path:** `golden-facts/{Topology}x{Workload}-{MMDDYY}.md`
```

### 2. Benchmark Environment

Critical context for reproducibility and analysis.

```markdown
## Benchmark Environment

### Runner (Benchmark Driver)
| Property | Value |
|----------|-------|
| Role | proxy / benchmark driver |
| Instance | c8g.xlarge |
| vCPU | 4 |
| RAM | 8 GB |
| Private IP | 10.0.1.20 |

### Target (Database Server)
| Property | Value |
|----------|-------|
| Role | primary / replica |
| Instance | r8g.xlarge |
| vCPU | 4 |
| RAM | 32 GB |
| Private IP | 10.0.1.10 |
| Storage | 4x gp3 RAID0 (DATA) + 4x gp3 RAID0 (WAL) |
| PostgreSQL | 16.x |
```

### 3. Scenario Context

Full scenario definition for understanding what was tested.

```markdown
## Scenario Context

### Scenario Definition
| Property | Value |
|----------|-------|
| ID | 11 |
| Name | postgres_tpcb |
| Description | Standard pgbench TPC-B with 100 clients |
| Benchmark Tool | pgbench |
| Dataset | TPC-B |
| Scale Factor | 1250 (~20GB) |

### Workload Parameters
| Parameter | Value |
|-----------|-------|
| Duration | 60s |
| Clients | 100 |
| Threads | 4 |
| Protocol | simple / extended / prepared |
| Transaction Type | TPC-B (default) / SELECT-only (-S) / Custom |

### Primary Command
```bash
PGPASSWORD=postgres pgbench -h 10.0.1.10 -U postgres bench \
  -c 100 -j 4 -T 60 -P 5 -M prepared --no-vacuum
```

### Command Flags Breakdown
| Flag | Value | Meaning |
|------|-------|---------|
| -c | 100 | Number of concurrent clients |
| -j | 4 | Number of worker threads |
| -T | 60 | Duration in seconds |
| -P | 5 | Progress report interval |
| -M | prepared | Query protocol (simple/extended/prepared) |
| -S | (if set) | SELECT-only mode |
| -C | (if set) | Establish new connection per transaction |
| --no-vacuum | (if set) | Skip vacuum before test |
```

### 4. Summary

Key metrics at a glance.

```markdown
## Summary

| Metric | Value |
|--------|-------|
| TPS | 11,057 |
| TPS/vCPU | 2,764 |
| Latency (avg) | 9.04ms |
| Latency (stddev) | 1.8ms |
| Cache Hit | 95.6% |
| Duration | 60s |
| Transactions | 663,420 |
```

### 5. Benchmark Output

Raw output for detailed analysis.

```markdown
## Benchmark Output

**Command:**
```bash
{full command with all flags}
```

**Output:**
```
{raw pgbench/fio output including progress lines}
```
```

### 6. Diagnostics

Time-series and PostgreSQL statistics from the TARGET machine.

```markdown
## Diagnostics

### iostat (Target: 10.0.1.10)
```
{time-series disk I/O from DB node}
```

### mpstat (Target: 10.0.1.10)
```
{time-series CPU from DB node}
```

### pg_stat_wal
```
{WAL statistics}
```

### pg_stat_bgwriter
```
{background writer stats}
```

### pg_stat_database
```
{database stats including blks_read, blks_hit}
```
```

### 7. Configuration Matrix (Full 52 Configs)

All configs from `scripts/config/*.env`, grouped by category:

```markdown
## Configuration Matrix

### OS - Memory (10 params)
| Parameter | Value | Source |
|-----------|-------|--------|
| vm.swappiness | 1 | os.env |
| vm.dirty_background_ratio | 1 | os.env |
| vm.dirty_ratio | 4 | os.env |
| vm.dirty_expire_centisecs | 200 | os.env |
| vm.dirty_writeback_centisecs | 100 | os.env |
| vm.overcommit_memory | 2 | os.env |
| vm.overcommit_ratio | 80 | os.env |
| vm.min_free_kbytes | 335544 | os.env |
| vm.zone_reclaim_mode | 0 | os.env |
| vm.nr_hugepages | 4382 | os.env |

### OS - File Descriptors (2 params)
| Parameter | Value | Source |
|-----------|-------|--------|
| fs.file-max | 2097152 | os.env |
| fs.aio-max-nr | 1048576 | os.env |

### OS - Kernel (2 params)
| Parameter | Value | Source |
|-----------|-------|--------|
| kernel.sched_autogroup_enabled | 0 | os.env |
| kernel.numa_balancing | 0 | os.env |

### OS - TCP (9 params)
| Parameter | Value | Source |
|-----------|-------|--------|
| net.core.somaxconn | 4096 | os.env |
| net.core.netdev_max_backlog | 2048 | os.env |
| net.core.rmem_default | 262144 | os.env |
| net.core.rmem_max | 16777216 | os.env |
| net.core.wmem_default | 262144 | os.env |
| net.core.wmem_max | 16777216 | os.env |
| net.ipv4.tcp_max_syn_backlog | 4096 | os.env |
| net.ipv4.tcp_tw_reuse | 1 | os.env |
| net.ipv4.tcp_fin_timeout | 15 | os.env |

### Disk (7 params)
| Parameter | Value | Source |
|-----------|-------|--------|
| DATA read_ahead_kb | 4096 | base.env |
| WAL read_ahead_kb | 4096 | base.env |
| DATA filesystem | xfs | base.env |
| WAL filesystem | xfs | base.env |
| DATA mount | /data | base.env |
| WAL mount | /wal | base.env |
| transparent_hugepage | never | os.env |

### PostgreSQL - Memory (6 params)
| Parameter | Value | Source |
|-----------|-------|--------|
| shared_buffers | 8GB | primary.env |
| effective_cache_size | 22GB | primary.env |
| work_mem | 5MB | primary.env |
| maintenance_work_mem | 1638MB | primary.env |
| huge_pages | try | primary.env |
| max_connections | 300 | primary.env |

### PostgreSQL - WAL (8 params)
| Parameter | Value | Source |
|-----------|-------|--------|
| wal_level | replica | primary.env |
| wal_compression | lz4 | primary.env |
| wal_sync_method | fdatasync | primary.env |
| wal_buffers | 64MB | primary.env |
| wal_writer_delay | 10ms | primary.env |
| synchronous_commit | on | primary.env |
| max_wal_size | 32GB | primary.env |
| min_wal_size | 2GB | primary.env |

### PostgreSQL - Checkpoint (2 params)
| Parameter | Value | Source |
|-----------|-------|--------|
| checkpoint_timeout | 15min | primary.env |
| checkpoint_completion_target | 0.9 | primary.env |

### PostgreSQL - Background Writer (3 params)
| Parameter | Value | Source |
|-----------|-------|--------|
| bgwriter_delay | 10ms | primary.env |
| bgwriter_lru_maxpages | 400 | primary.env |
| bgwriter_lru_multiplier | 4 | primary.env |

### PostgreSQL - I/O (3 params)
| Parameter | Value | Source |
|-----------|-------|--------|
| effective_io_concurrency | 200 | primary.env |
| random_page_cost | 1.1 | primary.env |
| seq_page_cost | 1.0 | primary.env |
```

### 8. Golden Fact Template

Exact format for baking agent. Copy and fill placeholders.

```markdown
## Golden Fact Template

> **Instructions for Baking Agent:**
> 1. Analyze benchmark results above
> 2. Check ceiling criteria (CPU >= 90% OR disk util >= 80%)
> 3. Verify Little's Law (TPS ~= clients / latency)
> 4. Fill Observation, Pitfall, Verdict sections
> 5. If CEILING CONFIRMED, save as: `golden-facts/{Topology}x{Workload}-{MMDDYY}.md`

---

# Golden Fact: {Topology} x {Workload}

**ID:** {Topology}x{Workload}-{MMDDYY}
**Date:** {date}
**Hardware:** {instance_type} ({vcpu} vCPU, {ram}GB RAM)
**Scenario:** {scenario_id} - {scenario_name}

## Ceiling Proof

### Metrics
| Metric | Value |
|--------|-------|
| TPS | {tps} |
| TPS/Core | {tps_per_core} |
| Latency (avg) | {latency_avg} |
| Cache Hit | {cache_hit_pct} |

### Little's Law Verification
```
TPS_theoretical = clients / latency
                = {clients} / {latency_sec}
                = {theoretical_tps}

TPS_actual      = {actual_tps}
Efficiency      = {efficiency}%
```

### Bottleneck Analysis
| Resource | Utilization | Bottleneck? |
|----------|-------------|-------------|
| CPU | {cpu_pct}% | {yes/no} |
| Disk (DATA) | {data_util}% | {yes/no} |
| Disk (WAL) | {wal_util}% | {yes/no} |
| WAL fsync | {wal_sync_ms}ms | {yes/no} |

**Primary Bottleneck:** {bottleneck_description}

## Configuration

{condensed config tables from Configuration Matrix}

## Observation

{observations_about_what_worked_and_why}

## Pitfall

{things_to_watch_out_for_edge_cases_warnings}

## Verdict

{CEILING CONFIRMED | CEILING NOT REACHED | NEEDS MORE TESTING}

{verdict_explanation}

---
*Baked from: results/{result_filename}*
```

---

## Golden Fact Output Format

When baked, golden fact is saved as single markdown file:

```
golden-facts/{Topology}x{Workload}-{MMDDYY}.md
```

Examples:
- `golden-facts/PrimaryxOLTP-010826.md`
- `golden-facts/ReplicaxOLTP-010826.md`
- `golden-facts/PrimaryxOLAP-010826.md`

---

## Config Source Mapping

| Category | Source File | Param Count |
|----------|-------------|-------------|
| OS - Memory | scripts/config/os.env | 10 |
| OS - File Descriptors | scripts/config/os.env | 2 |
| OS - Kernel | scripts/config/os.env | 2 |
| OS - TCP | scripts/config/os.env | 9 |
| Disk | scripts/config/base.env | 7 |
| PostgreSQL - Memory | scripts/config/primary.env | 6 |
| PostgreSQL - WAL | scripts/config/primary.env | 8 |
| PostgreSQL - Checkpoint | scripts/config/primary.env | 2 |
| PostgreSQL - Background Writer | scripts/config/primary.env | 3 |
| PostgreSQL - I/O | scripts/config/primary.env | 3 |
| **Total** | | **52** |

---

*Structure version: 2026-01-08*
