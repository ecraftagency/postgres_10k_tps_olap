# Tuning Guide

Mathematical rationale for every tuning decision.

## Philosophy

Every configuration value has a mathematical or empirical justification. No "magic numbers" - each setting can be derived from hardware specs, measured values, or PostgreSQL internals.

## Memory Tuning

### shared_buffers

**Goal**: Size buffer pool to hold working set while leaving room for OS cache.

**Formula**:
```
shared_buffers = RAM × 0.25 to 0.31

Example (64GB RAM):
  Conservative: 64GB × 0.25 = 16GB
  Aggressive:   64GB × 0.31 = 20GB

  We use 20GB (31%) for OLTP workloads
```

**Rationale**: PostgreSQL double-buffers through OS page cache. Setting shared_buffers too high wastes memory. 25-30% is optimal for most workloads.

### effective_cache_size

**Goal**: Tell planner how much memory is available for caching.

**Formula**:
```
effective_cache_size = RAM × 0.70

Example (64GB RAM):
  64GB × 0.70 = 44GB
```

**Rationale**: Includes shared_buffers + expected OS page cache. Helps planner choose index scans vs sequential scans.

### work_mem

**Goal**: Per-operation memory for sorts, hashes, etc.

**Formula**:
```
work_mem = (RAM - shared_buffers) / (max_connections × operations_per_query)

Example (64GB RAM, 500 connections, ~5 ops/query):
  (64GB - 20GB) / (500 × 5) = 44GB / 2500 = 17.6MB

  Round up with safety margin: 54MB for OLTP
  OLAP (fewer concurrent queries): 512MB
```

**Rationale**: Prevent disk spills during sorts/hashes. Higher values speed up complex queries but risk memory exhaustion under concurrency.

### HugePages

**Goal**: Reduce TLB misses for large shared_buffers.

**Formula**:
```
nr_hugepages = ceil(shared_buffers / 2MB) × 1.1

Example (20GB shared_buffers):
  20GB / 2MB = 10,240 pages
  10,240 × 1.1 = 11,264 → round to 11,000
```

**Verification**:
```bash
grep Huge /proc/meminfo
# HugePages_Total: 11000
# HugePages_Free:  ~500 (most used by PostgreSQL)
```

## Dirty Page Management

### The Problem

When dirty pages exceed a threshold, the kernel forces synchronous writeback, causing "I/O stalls" visible as latency spikes.

### vm.dirty_ratio

**Goal**: Cap maximum dirty memory to prevent stalls.

**Formula**:
```
max_dirty_bytes = disk_write_speed × acceptable_stall_time
dirty_ratio = (max_dirty_bytes / RAM) × 100

Example:
  disk_write_speed = 509 MB/s (from fio testing)
  acceptable_stall_time = 1 second
  max_dirty = 509 MB/s × 1s = 509 MB
  dirty_ratio = (509 MB / 64 GB) × 100 = 0.8%

  → Round up to 4% for safety margin
```

### vm.dirty_background_ratio

**Goal**: Start background writeback early to prevent hitting dirty_ratio.

**Formula**:
```
dirty_background_ratio = dirty_ratio / 4

Example:
  4% / 4 = 1%
```

**Rationale**: Background writeback starts at 1%, aggressive flushing at 4%. This provides a buffer zone for burst writes.

### vm.dirty_writeback_centisecs

**Goal**: Frequency of writeback thread wake-ups.

**Value**: `100` (1 second)

**Rationale**: More frequent wake-ups (100cs = 1s) provide smoother I/O without significant CPU overhead.

## Background Writer Tuning

### The Problem

Default bgwriter settings are too conservative:
- `bgwriter_delay = 200ms` (only 5 rounds/second)
- `bgwriter_lru_maxpages = 100` (only 800KB/round)
- Cleaning rate: 5 × 800KB = 4 MB/s

At 11,500 TPS with 8KB dirty pages per transaction (10% dirty rate):
- Dirty rate: 11,500 × 0.1 × 8KB = 9.2 MB/s
- Default bgwriter: 4 MB/s
- **FAIL!** Backend processes must write their own dirty pages.

### bgwriter_delay

**Goal**: Increase bgwriter frequency.

**Formula**:
```
rounds_per_second = 1000ms / bgwriter_delay

Example:
  Default: 1000 / 200 = 5 rounds/second
  Tuned:   1000 / 10  = 100 rounds/second
```

### bgwriter_lru_maxpages

**Goal**: Pages written per round.

**Formula**:
```
required_pages_per_second = dirty_rate_bytes / page_size
pages_per_round = required_pages_per_second / rounds_per_second

Example:
  dirty_rate = 9.2 MB/s = 9,420,800 bytes/s
  pages_per_second = 9,420,800 / 8192 = 1,150
  rounds_per_second = 100 (with delay=10ms)
  pages_per_round = 1,150 / 100 = 11.5

  → Set to 1000 for 10× headroom
```

### bgwriter_lru_multiplier

**Goal**: Aggressiveness in cleaning ahead of demand.

**Value**: `10.0`

**Rationale**: Clean 10× more pages than recent demand to stay ahead of workload spikes.

### Verification

```bash
psql -c "SELECT buffers_backend, buffers_clean FROM pg_stat_bgwriter"
# buffers_backend should be near 0
# buffers_clean should be increasing steadily
```

## WAL Tuning

### wal_buffers

**Goal**: Size WAL buffer to hold enough transactions for efficient batching.

**Formula**:
```
wal_size_per_transaction ≈ 2-4 KB (TPC-B)
concurrent_transactions = clients = 100
wal_buffers = transactions × size × safety_factor

Example:
  100 × 4KB × 4 = 1.6 MB minimum
  → Set to 256MB for checkpoint bursts
```

### max_wal_size

**Goal**: Control checkpoint frequency.

**Formula**:
```
wal_generation_rate = TPS × wal_per_transaction
checkpoint_interval = max_wal_size / wal_generation_rate

Example:
  TPS = 19,500
  wal_per_transaction ≈ 4 KB
  wal_rate = 19,500 × 4KB = 78 MB/s

  With max_wal_size = 50GB:
  checkpoint_interval = 50,000 MB / 78 MB/s = 641 seconds ≈ 10.7 minutes

  → Checkpoints every ~10 minutes (not every 5 minutes default)
```

### checkpoint_timeout

**Goal**: Maximum time between checkpoints.

**Value**: `30min`

**Rationale**: Allow max_wal_size to control checkpoints, not timeout. 30 minutes provides safety net without interfering with normal operation.

### checkpoint_completion_target

**Goal**: Spread checkpoint I/O over time.

**Value**: `0.9`

**Rationale**: Spread checkpoint writes over 90% of the checkpoint interval, reducing I/O spikes.

## Group Commit

### How It Works

PostgreSQL batches multiple transactions into single fsync operations:

```
Transaction 1 ─┐
Transaction 2 ─┼─→ [WAL Write] → [Single fsync] → All Committed
Transaction 3 ─┘
```

### commit_delay

**Goal**: Wait time to gather more transactions before fsync.

**Formula**:
```
optimal_delay = fsync_latency / expected_batch_size

Example:
  fsync_latency = 1.858 ms (from fio testing)
  At 11,500 TPS, transactions arrive every 87μs
  50μs delay = ~0.5 extra transactions per batch

  → 50μs is reasonable starting point
```

### commit_siblings

**Goal**: Minimum concurrent transactions to trigger delay.

**Value**: `10`

**Rationale**: Only delay when there are 10+ siblings who benefit from batching. Under light load, commit immediately.

### Verification

```
Batch size = TPS × fsync_latency / 1000
Example: 19,500 × 1.858 / 1000 = 36 transactions/fsync
```

## I/O Tuning

### effective_io_concurrency

**Goal**: Tell PostgreSQL how many parallel I/O operations disk can handle.

**Formula**:
```
effective_io_concurrency = RAID_disk_count × iops_per_disk / typical_iops_needed

Example (8-disk RAID10):
  Each gp3 can do 3000 base IOPS
  RAID10 provides n/2 = 4 disk equivalent
  4 × 3000 = 12,000 IOPS capacity

  → Set to 200 (practical limit for async I/O)
```

### read_ahead

**Goal**: Kernel read-ahead for sequential scans.

**Values**:
- DATA volume: `2048` sectors (1 MB) - for random I/O workloads
- WAL volume: `4096` sectors (2 MB) - for sequential writes

### random_page_cost

**Goal**: Tell planner cost of random vs sequential I/O.

**Formula**:
```
random_page_cost = random_latency / sequential_latency

Example (gp3 RAID10):
  random_latency ≈ 0.6 ms
  sequential_latency ≈ 0.5 ms
  ratio = 1.2

  → Set to 1.1 (favor index scans on fast storage)
```

## Parallelism

### max_parallel_workers_per_gather

**Goal**: Workers per parallel query.

**Formula**:
```
For OLTP: Limit to avoid resource contention
  max_parallel_workers_per_gather = vCPU / 2

For OLAP: Allow more parallelism
  max_parallel_workers_per_gather = vCPU / 2 to vCPU

Example (8 vCPU):
  OLTP: 4 workers per query
  OLAP: 4-8 workers per query
```

### JIT Compilation

**OLTP**: `jit = off`
- Short queries don't benefit from JIT overhead
- Compilation time > execution time

**OLAP**: `jit = on`
- Complex queries benefit from optimized code
- Compilation amortized over long execution

## Autovacuum Tuning

### autovacuum_naptime

**Goal**: How often to check for vacuum needs.

**Value**: `30s`

**Rationale**: More frequent checks (30s vs 1min) catch dead tuples earlier.

### autovacuum_vacuum_scale_factor

**Goal**: Table fraction that triggers vacuum.

**Value**: `0.05` (5%)

**Rationale**: Vacuum at 5% dead tuples instead of 20% default. Keeps tables cleaner.

### autovacuum_vacuum_cost_limit

**Goal**: I/O budget per vacuum round.

**Value**: `2000`

**Rationale**: Higher limit (2000 vs 200) allows faster vacuuming on fast storage.

## Testing Methodology

### Baseline Measurement

1. Run benchmark with default settings
2. Record TPS, latency, iostat, pg_stat_bgwriter

### Iterative Tuning

1. Change ONE parameter
2. Run benchmark
3. Compare metrics
4. Keep or revert

### Key Metrics to Watch

| Metric | Source | Good Sign | Bad Sign |
|--------|--------|-----------|----------|
| TPS | pgbench | Increasing | Decreasing |
| Latency | pgbench | Decreasing | Increasing |
| buffers_backend | pg_stat_bgwriter | Near 0 | Increasing |
| checkpoints_req | pg_stat_bgwriter | 0 | > 0 |
| %util | iostat | < 80% | > 90% |
| await | iostat | < 5ms | > 10ms |

## Summary: Key Formulas

```
# Memory
shared_buffers = RAM × 0.25-0.31
effective_cache_size = RAM × 0.70
work_mem = (RAM - shared_buffers) / (connections × ops_per_query)
nr_hugepages = ceil(shared_buffers / 2MB) × 1.1

# Dirty Pages
dirty_ratio = (disk_speed × stall_time / RAM) × 100
dirty_background_ratio = dirty_ratio / 4

# Background Writer
bgwriter_pages_per_sec = (TPS × dirty_rate × page_size) / page_size
required_delay = 1000 / (bgwriter_pages_per_sec / maxpages)

# WAL/Checkpoint
checkpoint_interval = max_wal_size / (TPS × wal_per_tx)

# Group Commit
batch_size = TPS × fsync_latency / 1000

# I/O
random_page_cost = random_latency / sequential_latency
```
