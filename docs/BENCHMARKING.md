# Benchmarking Guide

## Overview

The benchmark framework supports multiple workload types with consistent diagnostics and reporting.

## Workload Types

| Workload | Driver | Metric | Description |
|----------|--------|--------|-------------|
| `tpc-b` | pgbench | TPS | OLTP transactions (simple) |
| `tpc-c` | HammerDB | NOPM | OLTP transactions (complex) |
| `tpc-h` | HammerDB | QphH | OLAP analytical queries |

## Running Benchmarks

### Basic Usage

```bash
sudo python3 scripts/core/bench.py \
  --topology single-node \
  --hardware r8g.2xlarge \
  --workload tpc-b
```

### Full Options

```bash
sudo python3 scripts/core/bench.py \
  --topology|-L single-node    # Infrastructure topology
  --hardware|-H r8g.2xlarge    # Hardware context
  --workload|-W tpc-b          # Workload type
  --duration|-T 60             # Benchmark duration (seconds)
  --clients|-c 100             # Concurrent connections
  --no-warmup                  # Skip warmup phase
  --skip-verify                # Skip config verification
  --skip-ai                    # Skip AI analysis
  --diagnostics-only           # Collect diagnostics without benchmark
```

## Benchmark Phases

### 1. Config Verification

Before running, the framework verifies all settings match expected values:

```
--- Config Verification ---
  PostgreSQL: 12 checks passed
  OS: 5 checks passed
  Disk: 4 checks passed
```

If verification fails:
```
  WARNING: 3 settings don't match expected values
  Continuing with benchmark anyway...
```

Use `--skip-verify` to bypass verification.

### 2. Warmup Phase

30-second warmup to:
- Fill buffer pool with hot data
- Warm up connection pools
- Stabilize autovacuum

Use `--no-warmup` to skip (not recommended for production benchmarks).

### 3. Benchmark Phase

Actual benchmark execution with parallel diagnostic collection:
- iostat (disk I/O metrics)
- mpstat (CPU per-core)
- vmstat (memory/swap)
- pg_stat_* (PostgreSQL internals)

### 4. Report Generation

Automatic generation of:
- Markdown report with all metrics
- Config matrix (all 117 parameters)
- Verification results
- Full diagnostic output
- AI analysis (optional)

## Output Structure

```
results/
└── {topology}/
    └── {hardware}--{workload}/
        ├── {workload}_{timestamp}.md        # Main report
        └── {workload}_{timestamp}_ai.md     # With AI analysis
```

Example:
```
results/
└── single-node/
    └── r8g.2xlarge--tpc-b/
        ├── tpc-b_20260105-103045.md
        └── tpc-b_20260105-103045_ai.md
```

## Report Contents

### Summary Section

```markdown
## Summary

| Metric | Value |
|--------|-------|
| **TPS** | **19,554** |
| Duration | 60s |
| Avg Latency | 5.11ms |
| Latency Stddev | 2.34ms |
| P99 Latency | 12.45ms |
| Total Transactions | 1,173,240 |
```

### Config Matrix

Full 117-parameter configuration grouped by category:
- Instance specs
- RAID configuration
- OS tuning
- PostgreSQL tuning
- Benchmark settings

### Verification Table

```markdown
| Category | Setting | Expected | Actual | Status |
|----------|---------|----------|--------|--------|
| PostgreSQL | shared_buffers | 20GB | 20GB | PASS |
| OS | vm.nr_hugepages | 11000 | 11000 | PASS |
```

### Diagnostics

- iostat output (disk I/O)
- mpstat output (CPU usage)
- pg_stat_bgwriter (checkpoint activity)
- pg_stat_wal (WAL throughput)
- Wait event analysis

## Best Practices

### Consistent Benchmarking

1. **Always verify config** - Don't skip `--skip-verify` for production benchmarks
2. **Use warmup** - 30s warmup ensures stable results
3. **Multiple runs** - Run 3-5 times and take median
4. **Sufficient duration** - Minimum 60s, prefer 300s for accurate results

### Comparing Results

To compare across configurations:

```bash
# Run same benchmark on different hardware
sudo python3 scripts/core/bench.py -L single-node -H r8g.xlarge -W tpc-b
sudo python3 scripts/core/bench.py -L single-node -H r8g.2xlarge -W tpc-b
sudo python3 scripts/core/bench.py -L single-node -H r8g.4xlarge -W tpc-b
```

### Scaling Tests

Test different client counts:

```bash
for clients in 50 100 200 400; do
  sudo python3 scripts/core/bench.py \
    -L single-node -H r8g.2xlarge -W tpc-b \
    -c $clients -T 60
done
```

### Duration Tests

```bash
for duration in 60 300 600; do
  sudo python3 scripts/core/bench.py \
    -L single-node -H r8g.2xlarge -W tpc-b \
    -T $duration -c 100
done
```

## Interpreting Results

### TPS (Transactions Per Second)

- **Good**: 15,000+ TPS on r8g.2xlarge
- **Excellent**: 19,000+ TPS on r8g.2xlarge
- **Investigate**: < 10,000 TPS (check config, iostat)

### Latency

| Metric | Good | Excellent | Investigate |
|--------|------|-----------|-------------|
| Avg Latency | < 10ms | < 6ms | > 15ms |
| P99 Latency | < 20ms | < 15ms | > 30ms |
| Stddev | < 5ms | < 3ms | > 10ms |

### Diagnostic Indicators

**iostat**: Look for:
- `%util` > 80% = disk bottleneck
- `await` > 5ms = high I/O latency
- `w/s` should match expected write rate

**mpstat**: Look for:
- `%usr` + `%sys` > 90% = CPU bottleneck
- High `%iowait` = disk bottleneck

**pg_stat_bgwriter**: Look for:
- `buffers_backend` high = bgwriter too slow
- `checkpoints_req` > 0 = checkpoint pressure

## Troubleshooting Low Performance

### Check 1: Config Verification

```bash
sudo python3 scripts/core/bench.py -L single-node -H r8g.2xlarge -W tpc-b
# Look for FAIL in verification output
```

### Check 2: Disk I/O

```bash
iostat -xz 1
# High %util or await indicates disk bottleneck
```

### Check 3: Checkpoints

```bash
sudo -u postgres psql -c "SELECT * FROM pg_stat_bgwriter"
# High buffers_backend = tune bgwriter
# checkpoints_req > 0 = increase max_wal_size
```

### Check 4: Wait Events

```bash
sudo -u postgres psql -c "
SELECT wait_event_type, wait_event, count(*)
FROM pg_stat_activity
WHERE state = 'active'
GROUP BY 1, 2
ORDER BY 3 DESC
"
```

Common bottlenecks:
- `LWLock:BufferMapping` = increase shared_buffers
- `IO:WALWrite` = tune WAL settings
- `Lock:transactionid` = application lock contention

## AI Analysis

When enabled (default), the framework sends the report to Gemini for analysis:

```markdown
## AI Analysis

### Performance Assessment
- TPS: 19,554 (Excellent)
- Latency: 5.11ms avg (Good)
- Stability: Low stddev indicates consistent performance

### Bottleneck Analysis
- No significant disk bottleneck (util < 50%)
- CPU usage well-distributed
- Checkpoint frequency optimal

### Recommendations
1. Current config is well-optimized
2. Consider testing with 150 clients for higher TPS
3. Monitor checkpoint timing under sustained load
```

Use `--skip-ai` to disable AI analysis.
