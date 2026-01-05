# Configuration Reference

Complete reference for all configuration parameters.

## Config Layers

Configuration is split into two layers:

1. **Hardware Context** (`hardware/{instance}/hardware.env`) - Instance specs, RAID config, OS tuning
2. **Workload Context** (`workloads/{workload}/tuning.env`) - PostgreSQL tuning, benchmark settings

The benchmark framework merges these at runtime.

## Hardware Context Parameters

### Instance Specifications

| Parameter | Description | Example |
|-----------|-------------|---------|
| `HARDWARE_CONTEXT` | Context identifier | `r8g.2xlarge` |
| `INSTANCE_TYPE` | AWS instance type | `r8g.2xlarge` |
| `VCPU` | Virtual CPU count | `8` |
| `RAM_GB` | Memory in GB | `64` |
| `NETWORK_GBPS` | Network bandwidth | `15` |
| `EBS_GBPS` | EBS bandwidth | `10` |

### RAID Configuration - DATA Volume

| Parameter | Description | Default |
|-----------|-------------|---------|
| `DATA_MOUNT` | Mount point | `/data` |
| `DATA_DISK_COUNT` | Number of EBS volumes | `8` |
| `DATA_DISK_SIZE_GB` | Size per volume | `50` |
| `DATA_RAID_LEVEL` | RAID level | `10` |
| `DATA_RAID_CHUNK` | Chunk size | `64K` |
| `DATA_READ_AHEAD` | Read-ahead sectors | `2048` |
| `DATA_FILESYSTEM` | Filesystem type | `xfs` |
| `DATA_MOUNT_OPTS` | Mount options | `noatime,nodiratime,logbufs=8` |

### RAID Configuration - WAL Volume

| Parameter | Description | Default |
|-----------|-------------|---------|
| `WAL_MOUNT` | Mount point | `/wal` |
| `WAL_DISK_COUNT` | Number of EBS volumes | `8` |
| `WAL_DISK_SIZE_GB` | Size per volume | `30` |
| `WAL_RAID_LEVEL` | RAID level | `10` |
| `WAL_RAID_CHUNK` | Chunk size | `256K` |
| `WAL_READ_AHEAD` | Read-ahead sectors | `4096` |
| `WAL_FILESYSTEM` | Filesystem type | `xfs` |
| `WAL_MOUNT_OPTS` | Mount options | `noatime,nodiratime,logbufs=8` |

### OS Tuning Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `VM_SWAPPINESS` | Swap tendency | `1` |
| `VM_DIRTY_RATIO` | Max dirty memory % | `4` |
| `VM_DIRTY_BG_RATIO` | Writeback threshold % | `1` |
| `VM_DIRTY_EXPIRE_CENTISECS` | Dirty page expire | `500` |
| `VM_DIRTY_WRITEBACK_CENTISECS` | Writeback interval | `100` |
| `VM_MIN_FREE_KBYTES` | Reserved memory KB | `671088` |
| `VM_NR_HUGEPAGES` | HugePages count | `11000` |
| `KERNEL_SCHED_MIGRATION_COST_NS` | Scheduler tuning | `5000000` |
| `KERNEL_SCHED_AUTOGROUP_ENABLED` | Autogroup | `0` |

### Networking

| Parameter | Description | Example |
|-----------|-------------|---------|
| `NET_SOMAXCONN` | Socket backlog | `65535` |
| `NET_TCP_MAX_SYN_BACKLOG` | SYN backlog | `65535` |
| `NET_TCP_FIN_TIMEOUT` | FIN timeout | `10` |
| `NET_TCP_KEEPALIVE_TIME` | Keepalive time | `60` |
| `NET_TCP_KEEPALIVE_INTVL` | Keepalive interval | `10` |
| `NET_TCP_KEEPALIVE_PROBES` | Keepalive probes | `6` |

## Workload Context Parameters

### PostgreSQL Memory

| Parameter | Description | OLTP | OLAP |
|-----------|-------------|------|------|
| `PG_SHARED_BUFFERS` | Buffer pool size | `20GB` | `16GB` |
| `PG_EFFECTIVE_CACHE_SIZE` | Planner cache estimate | `44GB` | `48GB` |
| `PG_WORK_MEM` | Per-operation memory | `54MB` | `512MB` |
| `PG_MAINTENANCE_WORK_MEM` | Maintenance memory | `2GB` | `4GB` |
| `PG_HUGE_PAGES` | Use HugePages | `on` | `on` |

### PostgreSQL WAL

| Parameter | Description | Example |
|-----------|-------------|---------|
| `PG_WAL_LEVEL` | WAL detail level | `replica` |
| `PG_WAL_BUFFERS` | WAL buffer size | `256MB` |
| `PG_MAX_WAL_SIZE` | Max WAL before checkpoint | `50GB` |
| `PG_MIN_WAL_SIZE` | Min WAL to keep | `10GB` |
| `PG_WAL_COMPRESSION` | Compress WAL | `zstd` |
| `PG_WAL_INIT_ZERO` | Pre-zero WAL | `off` |
| `PG_WAL_RECYCLE` | Recycle WAL files | `on` |
| `PG_SYNCHRONOUS_COMMIT` | Sync commit level | `on` |
| `PG_FSYNC` | Enable fsync | `on` |
| `PG_FULL_PAGE_WRITES` | Full page writes | `on` |

### PostgreSQL Checkpoint

| Parameter | Description | Example |
|-----------|-------------|---------|
| `PG_CHECKPOINT_TIMEOUT` | Max time between checkpoints | `30min` |
| `PG_CHECKPOINT_COMPLETION_TARGET` | Checkpoint spread | `0.9` |
| `PG_CHECKPOINT_FLUSH_AFTER` | Flush after bytes | `256kB` |

### PostgreSQL Background Writer

| Parameter | Description | Example |
|-----------|-------------|---------|
| `PG_BGWRITER_DELAY` | Wake interval | `10ms` |
| `PG_BGWRITER_LRU_MAXPAGES` | Max pages per round | `1000` |
| `PG_BGWRITER_LRU_MULTIPLIER` | Aggressiveness | `10.0` |
| `PG_BGWRITER_FLUSH_AFTER` | Flush threshold | `512kB` |

### PostgreSQL Parallelism

| Parameter | Description | OLTP | OLAP |
|-----------|-------------|------|------|
| `PG_MAX_WORKER_PROCESSES` | Total workers | `8` | `16` |
| `PG_MAX_PARALLEL_WORKERS` | Parallel query workers | `4` | `8` |
| `PG_MAX_PARALLEL_WORKERS_PER_GATHER` | Workers per query | `2` | `4` |
| `PG_MAX_PARALLEL_MAINT_WORKERS` | Maintenance workers | `4` | `4` |
| `PG_PARALLEL_LEADER_PARTICIPATION` | Leader participates | `on` | `on` |

### PostgreSQL I/O

| Parameter | Description | Example |
|-----------|-------------|---------|
| `PG_EFFECTIVE_IO_CONCURRENCY` | Async I/O depth | `200` |
| `PG_MAINTENANCE_IO_CONCURRENCY` | Maintenance I/O depth | `200` |
| `PG_IO_COMBINE_LIMIT` | I/O combine limit | `128kB` |

### PostgreSQL Connections

| Parameter | Description | Example |
|-----------|-------------|---------|
| `PG_MAX_CONNECTIONS` | Max connections | `500` |
| `PG_SUPERUSER_RESERVED_CONNECTIONS` | Reserved for superuser | `5` |

### PostgreSQL Autovacuum

| Parameter | Description | Example |
|-----------|-------------|---------|
| `PG_AUTOVACUUM` | Enable autovacuum | `on` |
| `PG_AUTOVACUUM_MAX_WORKERS` | Vacuum workers | `4` |
| `PG_AUTOVACUUM_NAPTIME` | Check interval | `30s` |
| `PG_AUTOVACUUM_VACUUM_THRESHOLD` | Rows before vacuum | `50` |
| `PG_AUTOVACUUM_VACUUM_SCALE_FACTOR` | Scale factor | `0.05` |
| `PG_AUTOVACUUM_VACUUM_COST_LIMIT` | Cost limit | `2000` |
| `PG_AUTOVACUUM_VACUUM_COST_DELAY` | Cost delay | `2ms` |

### PostgreSQL Commit

| Parameter | Description | Example |
|-----------|-------------|---------|
| `PG_COMMIT_DELAY` | Group commit wait | `50` |
| `PG_COMMIT_SIBLINGS` | Min siblings for delay | `10` |

### PostgreSQL Planner

| Parameter | Description | Example |
|-----------|-------------|---------|
| `PG_RANDOM_PAGE_COST` | Random I/O cost | `1.1` |
| `PG_SEQ_PAGE_COST` | Sequential I/O cost | `1.0` |
| `PG_CPU_TUPLE_COST` | Tuple processing cost | `0.01` |
| `PG_CPU_INDEX_TUPLE_COST` | Index tuple cost | `0.005` |
| `PG_CPU_OPERATOR_COST` | Operator cost | `0.0025` |
| `PG_DEFAULT_STATISTICS_TARGET` | Statistics detail | `100` |
| `PG_JIT` | Enable JIT | `off` (OLTP) / `on` (OLAP) |

### PostgreSQL Logging

| Parameter | Description | Example |
|-----------|-------------|---------|
| `PG_LOGGING_COLLECTOR` | Enable log collector | `on` |
| `PG_LOG_DESTINATION` | Log destination | `stderr` |
| `PG_LOG_DIRECTORY` | Log directory | `log` |
| `PG_LOG_FILENAME` | Log filename pattern | `postgresql-%Y-%m-%d_%H%M%S.log` |
| `PG_LOG_MIN_DURATION_STATEMENT` | Slow query threshold | `1000` |
| `PG_LOG_CHECKPOINTS` | Log checkpoints | `on` |
| `PG_LOG_CONNECTIONS` | Log connections | `off` |
| `PG_LOG_DISCONNECTIONS` | Log disconnections | `off` |
| `PG_LOG_LOCK_WAITS` | Log lock waits | `on` |
| `PG_LOG_TEMP_FILES` | Log temp files | `0` |
| `PG_LOG_AUTOVACUUM_MIN_DURATION` | Log vacuum | `1000` |

### Benchmark Settings

| Parameter | Description | Example |
|-----------|-------------|---------|
| `PGBENCH_SCALE` | pgbench scale factor | `1000` |
| `PGBENCH_CLIENTS` | Default clients | `100` |
| `PGBENCH_DURATION` | Default duration | `60` |
| `BENCHMARK_WARMUP` | Warmup duration | `30` |

## Hardware Configurations

### r8g.xlarge (4 vCPU, 32GB RAM)

```bash
# Key settings
VCPU=4
RAM_GB=32
VM_NR_HUGEPAGES=5500
PG_SHARED_BUFFERS=8GB
PG_EFFECTIVE_CACHE_SIZE=22GB
PG_MAX_PARALLEL_WORKERS=2
```

### r8g.2xlarge (8 vCPU, 64GB RAM)

```bash
# Key settings
VCPU=8
RAM_GB=64
VM_NR_HUGEPAGES=11000
PG_SHARED_BUFFERS=20GB
PG_EFFECTIVE_CACHE_SIZE=44GB
PG_MAX_PARALLEL_WORKERS=4
```

### r8g.4xlarge (16 vCPU, 128GB RAM)

```bash
# Key settings
VCPU=16
RAM_GB=128
VM_NR_HUGEPAGES=17600
PG_SHARED_BUFFERS=32GB
PG_EFFECTIVE_CACHE_SIZE=90GB
PG_MAX_PARALLEL_WORKERS=8
```

## Scaling Guidelines

### Memory Scaling

| RAM | shared_buffers | effective_cache_size | HugePages |
|-----|----------------|---------------------|-----------|
| 32GB | 8GB (25%) | 22GB (70%) | 5,500 |
| 64GB | 20GB (31%) | 44GB (69%) | 11,000 |
| 128GB | 32GB (25%) | 90GB (70%) | 17,600 |

### CPU Scaling

| vCPU | max_workers | parallel_per_gather | autovacuum_workers |
|------|-------------|--------------------|--------------------|
| 4 | 4 | 2 | 2 |
| 8 | 8 | 4 | 4 |
| 16 | 16 | 8 | 6 |

### I/O Scaling

| RAID Disks | effective_io_concurrency | maintenance_io_concurrency |
|------------|--------------------------|---------------------------|
| 4 | 100 | 100 |
| 8 | 200 | 200 |
| 16 | 400 | 400 |

## Modifying Configuration

### Adding New Hardware Context

```bash
# 1. Create directory
mkdir -p scripts2/hardware/r8g.8xlarge

# 2. Copy template
cp scripts2/hardware/r8g.2xlarge/hardware.env scripts2/hardware/r8g.8xlarge/

# 3. Edit values
vim scripts2/hardware/r8g.8xlarge/hardware.env

# 4. Create terraform vars
vim terraform/hardware/r8g.8xlarge.tfvars
```

### Adding New Workload Context

```bash
# 1. Create directory
mkdir -p scripts2/workloads/custom

# 2. Copy template
cp scripts2/workloads/tpc-b/tuning.env scripts2/workloads/custom/

# 3. Edit values
vim scripts2/workloads/custom/tuning.env
```
