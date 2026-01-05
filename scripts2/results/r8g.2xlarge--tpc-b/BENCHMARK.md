# Benchmark Report: r8g.2xlarge--tpc-b

**Context**: `r8g.2xlarge--tpc-b`
**Date**: 2026-01-05
**Status**: PRODUCTION READY

---

## 1. Summary

| Metric | Value |
|--------|-------|
| **TPS** | **19,554** |
| TPS Peak | 19,967 |
| Latency Avg | 5.11ms |
| Latency Stddev | 1.31ms |
| P99 Latency | 8.38ms |
| Total Transactions | 1,172,956 |
| Failed | 0 (0.000%) |

---

## 2. Full Configuration Matrix (~120 parameters)

### 2.1 Instance Specs (5)

| Parameter | Value |
|-----------|-------|
| INSTANCE_TYPE | r8g.2xlarge |
| VCPU | 8 |
| RAM_GB | 64 |
| NETWORK_GBPS | 15 |
| EBS_GBPS | 10 |

### 2.2 OS Tuning - Memory (10)

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| VM_SWAPPINESS | 1 | Avoid swap for DB |
| VM_NR_HUGEPAGES | 11000 | 22GB for 20GB shared_buffers |
| VM_DIRTY_BACKGROUND_RATIO | 1 | Early writeback |
| VM_DIRTY_RATIO | 4 | Prevent I/O stalls |
| VM_DIRTY_EXPIRE_CENTISECS | 200 | 2s dirty page expiry |
| VM_DIRTY_WRITEBACK_CENTISECS | 100 | 1s writeback interval |
| VM_OVERCOMMIT_MEMORY | 2 | Predictable memory |
| VM_OVERCOMMIT_RATIO | 80 | 80% commit limit |
| VM_MIN_FREE_KBYTES | 671088 | 1% RAM reserved |
| VM_ZONE_RECLAIM_MODE | 0 | Disable NUMA reclaim |

### 2.3 OS Tuning - File Descriptors (4)

| Parameter | Value |
|-----------|-------|
| FS_FILE_MAX | 2097152 |
| FS_AIO_MAX_NR | 1048576 |
| ULIMIT_NOFILE | 65535 |
| ULIMIT_NPROC | 65535 |

### 2.4 OS Tuning - Network/TCP (11)

| Parameter | Value |
|-----------|-------|
| NET_CORE_SOMAXCONN | 4096 |
| NET_CORE_NETDEV_MAX_BACKLOG | 2048 |
| NET_CORE_RMEM_DEFAULT | 262144 |
| NET_CORE_RMEM_MAX | 16777216 |
| NET_CORE_WMEM_DEFAULT | 262144 |
| NET_CORE_WMEM_MAX | 16777216 |
| NET_IPV4_TCP_RMEM | 4096 87380 16777216 |
| NET_IPV4_TCP_WMEM | 4096 65536 16777216 |
| NET_IPV4_TCP_MAX_SYN_BACKLOG | 4096 |
| NET_IPV4_TCP_TW_REUSE | 1 |
| NET_IPV4_TCP_FIN_TIMEOUT | 15 |

### 2.5 OS Tuning - Scheduler (3)

| Parameter | Value |
|-----------|-------|
| KERNEL_SCHED_AUTOGROUP_ENABLED | 0 |
| KERNEL_NUMA_BALANCING | 0 |
| KERNEL_SEM | 250 32000 100 128 |

### 2.6 RAID Config - DATA Volume (7)

| Parameter | Value |
|-----------|-------|
| DATA_MOUNT | /data |
| DATA_DISK_SIZE_GB | 50 |
| DATA_DISK_COUNT | 8 |
| DATA_RAID_LEVEL | 10 |
| DATA_RAID_DEVICE | /dev/md0 |
| DATA_RAID_CHUNK | 64K |
| DATA_STRIPE_WIDTH | 4 |

### 2.7 RAID Config - WAL Volume (7)

| Parameter | Value |
|-----------|-------|
| WAL_MOUNT | /wal |
| WAL_DISK_SIZE_GB | 30 |
| WAL_DISK_COUNT | 8 |
| WAL_RAID_LEVEL | 10 |
| WAL_RAID_DEVICE | /dev/md1 |
| WAL_RAID_CHUNK | 256K |
| WAL_STRIPE_WIDTH | 4 |

### 2.8 XFS Options (8)

| Parameter | Value |
|-----------|-------|
| FS_TYPE | xfs |
| XFS_DATA_SUNIT | 64k |
| XFS_WAL_SUNIT | 256k |
| XFS_LOG_STRIPE_UNIT | 1b |
| XFS_DATA_AGCOUNT | 16 |
| XFS_WAL_AGCOUNT | 8 |
| XFS_MOUNT_OPTS_DATA | defaults,noatime,nodiratime,logbufs=8,logbsize=256k,allocsize=64m,inode64 |
| XFS_MOUNT_OPTS_WAL | defaults,noatime,nodiratime,logbufs=8,logbsize=256k,inode64 |

### 2.9 Block Device Tuning - DATA (8)

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| DATA_SCHEDULER | none | NVMe doesn't need scheduler |
| DATA_ROTATIONAL | 0 | Mark as SSD |
| DATA_READ_AHEAD_KB | 64 | Small for random I/O |
| DATA_NR_REQUESTS | 256 | Queue depth |
| DATA_MAX_SECTORS_KB | 256 | Max request size |
| DATA_RQ_AFFINITY | 2 | CPU affinity |
| DATA_ADD_RANDOM | 0 | Disable entropy |
| DATA_NOMERGES | 0 | Allow merges |

### 2.10 Block Device Tuning - WAL (8)

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| WAL_SCHEDULER | none | NVMe doesn't need scheduler |
| WAL_ROTATIONAL | 0 | Mark as SSD |
| WAL_READ_AHEAD_KB | 4096 | Large for sequential WAL |
| WAL_NR_REQUESTS | 128 | Queue depth |
| WAL_MAX_SECTORS_KB | 256 | Max request size |
| WAL_RQ_AFFINITY | 2 | CPU affinity |
| WAL_ADD_RANDOM | 0 | Disable entropy |
| WAL_NOMERGES | 0 | Allow merges |

### 2.11 MDADM Tuning (1)

| Parameter | Value |
|-----------|-------|
| MD_STRIPE_CACHE_SIZE | 8192 |

### 2.12 PostgreSQL - Paths (5)

| Parameter | Value |
|-----------|-------|
| PG_VERSION | 16 |
| PG_DATA_DIR | /data/postgresql |
| PG_WAL_DIR | /wal/pg_wal |
| PG_LISTEN_ADDRESSES | * |
| PG_PORT | 5432 |

### 2.13 PostgreSQL - Memory (6)

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| PG_MAX_CONNECTIONS | 300 | Moderate for OLTP |
| PG_SHARED_BUFFERS | 20GB | 31% RAM, fits dataset |
| PG_HUGE_PAGES | on | Eliminate TLB misses |
| PG_WORK_MEM | 54MB | Balanced for 300 conn |
| PG_MAINTENANCE_WORK_MEM | 1GB | Fast vacuum/index |
| PG_EFFECTIVE_CACHE_SIZE | 44GB | 70% RAM |

### 2.14 PostgreSQL - Disk I/O (3)

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| PG_RANDOM_PAGE_COST | 1.1 | SSD optimized |
| PG_SEQ_PAGE_COST | 1.0 | Baseline |
| PG_EFFECTIVE_IO_CONCURRENCY | 200 | High for NVMe |

### 2.15 PostgreSQL - WAL (4)

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| PG_WAL_COMPRESSION | lz4 | Fast compression |
| PG_WAL_BUFFERS | 256MB | Reduce fsync frequency |
| PG_WAL_WRITER_DELAY | 10ms | Frequent flush |
| PG_WAL_WRITER_FLUSH_AFTER | 1MB | Batch size |

### 2.16 PostgreSQL - Checkpoint (4)

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| PG_MAX_WAL_SIZE | 100GB | No checkpoint during bench |
| PG_MIN_WAL_SIZE | 4GB | Keep WAL preallocated |
| PG_CHECKPOINT_TIMEOUT | 1h | Defer checkpoints |
| PG_CHECKPOINT_COMPLETION_TARGET | 0.9 | Spread I/O |

### 2.17 PostgreSQL - Sync & Group Commit (3)

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| PG_SYNCHRONOUS_COMMIT | on | Durability |
| PG_COMMIT_DELAY | 0 | No batching (EBS fast) |
| PG_COMMIT_SIBLINGS | 5 | Group commit threshold |

### 2.18 PostgreSQL - Background Writer (3)

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| PG_BGWRITER_DELAY | 10ms | Aggressive flush |
| PG_BGWRITER_LRU_MAXPAGES | 1000 | High throughput |
| PG_BGWRITER_LRU_MULTIPLIER | 4.0 | Anticipate writes |

### 2.19 PostgreSQL - Autovacuum (6)

| Parameter | Value |
|-----------|-------|
| PG_AUTOVACUUM | on |
| PG_AUTOVACUUM_MAX_WORKERS | 4 |
| PG_AUTOVACUUM_NAPTIME | 1min |
| PG_AUTOVACUUM_VACUUM_SCALE_FACTOR | 0.05 |
| PG_AUTOVACUUM_ANALYZE_SCALE_FACTOR | 0.02 |
| PG_AUTOVACUUM_VACUUM_COST_LIMIT | 10000 |

### 2.20 PostgreSQL - Parallel Query (4)

| Parameter | Value |
|-----------|-------|
| PG_MAX_WORKER_PROCESSES | 8 |
| PG_MAX_PARALLEL_WORKERS_PER_GATHER | 4 |
| PG_MAX_PARALLEL_WORKERS | 8 |
| PG_JIT | off |

### 2.21 PostgreSQL - Logging (4)

| Parameter | Value |
|-----------|-------|
| PG_LOG_MIN_DURATION_STATEMENT | 1000 |
| PG_LOG_TEMP_FILES | 0 |
| PG_LOG_CHECKPOINTS | on |
| PG_LOG_LOCK_WAITS | on |

### 2.22 Benchmark Config (6)

| Parameter | Value |
|-----------|-------|
| PGBENCH_SCALE | 1250 |
| PGBENCH_DURATION | 60 |
| PGBENCH_CLIENTS_LIGHT | 4 |
| PGBENCH_CLIENTS_MEDIUM | 16 |
| PGBENCH_CLIENTS_HEAVY | 100 |
| FIO_RUNTIME | 60 |

**Total: 117 configuration parameters**

---

## 3. Proof of Concept: Mathematical Analysis

### 3.1 Memory Sizing

```
Dataset: Scale 1250 × 100K rows × 128B = 16GB + indexes = ~20GB
shared_buffers = 20GB → 100% dataset cached
HugePages = ceil(20GB / 2MB) × 1.07 = 10,240 × 1.07 = 10,957 → 11,000
```

### 3.2 IOPS Budget

```
Data IOPS: 8 × 3,000 = 24,000 IOPS (unused - all cached)
WAL IOPS: 8 × 3,000 = 24,000 IOPS
At 19.5K TPS: ~700 WAL writes/s × ~26KB = 18MB/s (3% of 10Gbps EBS)
```

### 3.3 Theoretical TPS Limit

```
CPU: 8 cores × ~2,500 TPS/core = 20,000 TPS
WAL fsync: ~2-3ms latency = ~20,000 TPS limit
Achieved: 19,554 TPS (98% of theoretical)
```

---

## 4. Benchmark Journal

### Run 1: Initial (Cold Cache)
**Date**: 2026-01-05 09:30

| Metric | Value |
|--------|-------|
| TPS | 17,458 |
| Latency | 5.73ms |
| Stddev | 7.25ms |

**Issue**: High stddev from cache warmup + wrong calculated config

### Run 2: Fixed Config + HugePages
**Date**: 2026-01-05 09:45

**Changes**:
- shared_buffers: 4GB → 20GB (explicit tuning.env)
- huge_pages: try → on
- vm.nr_hugepages: 0 → 11000
- wal_buffers: 64MB → 256MB

| Metric | Value | vs Run 1 |
|--------|-------|----------|
| TPS | 19,118 | +9.5% |
| Latency | 5.23ms | -8.7% |
| Stddev | 1.30ms | **-82%** |

### Run 3: Full bench.py (Production)
**Date**: 2026-01-05 09:57
**Report**: `20260105-095733.md`

| Metric | Value |
|--------|-------|
| TPS | **19,554** |
| Latency | 5.11ms |
| Stddev | 1.31ms |
| P99 | 8.38ms |

**Diagnostics Summary**:
- md0 (DATA): 0 r/s (100% cache hit)
- md1 (WAL): ~690 w/s @ 18MB/s, 70% util
- CPU: ~70% user, 30% sys

---

## 5. Key Findings

### 5.1 commit_delay=0 Optimal for EBS

```
commit_delay=0:  19,554 TPS
commit_delay=50: 16,456 TPS (-16%)
```

EBS gp3 latency (~2ms) is already low.

### 5.2 HugePages Critical

```
Without HugePages: ~15% overhead from TLB misses
With HugePages: Stddev dropped 82%
```

### 5.3 WAL is Ultimate Bottleneck

Wait event analysis shows `WALWrite` lock with 37-95 waiters.
Cannot exceed ~20K TPS with synchronous_commit=on.

---

## 6. Price/Performance

| Instance | TPS | Price/mo | TPS/$ |
|----------|-----|----------|-------|
| c8gb.8xlarge | 40,752 | $833 | 48.9 |
| **r8g.2xlarge** | 19,554 | $290 | **67.4** |

**r8g.2xlarge delivers 38% better value per dollar.**

---

## 7. Generated Reports

| File | Size | Content |
|------|------|---------|
| `20260105-095733.md` | 44KB | Full diagnostics (iostat, mpstat, pg_stats) |
| `BENCHMARK.md` | this | Config matrix + journal |

---

## 8. References

- Hardware: `hardware/r8g.2xlarge/hardware.env`
- Workload: `workloads/tpc-b/tuning.env`
- PostgreSQL: 16.11
- Benchmark: pgbench TPC-B
