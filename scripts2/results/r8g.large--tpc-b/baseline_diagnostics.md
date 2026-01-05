# Benchmark Report: TPC-B

**Date:** 2026-01-05 12:52:22
**Context:** `single-node/r8g.large--tpc-b`
**Hardware:** r8g.large (2 vCPU, 16 GB RAM)
**Workload:** tpc-b

## Summary

| Metric | Value |
|--------|-------|
| **TPS** | **4,844** |
| Duration | 60s |
| Avg Latency | 10.31ms |
| Latency Stddev | 3.40ms |
| P99 Latency | 18.81ms |
| Total Transactions | 290,646 |

### Additional Metrics

| Metric | Value |
|--------|-------|
| clients | 50 |
| scale | 204 |

---

## Configuration Matrix

**Context:** `single-node/r8g.large--tpc-b`
**Hardware:** r8g.large (2 vCPU, 16 GB RAM)
**Workload:** tpc-b

### PostgreSQL - Memory

| Setting | Value |
|---------|-------|
| shared_buffers | `4GB` |
| huge_pages | `try` |
| work_mem | `16MB` |
| maintenance_work_mem | `256MB` |
| effective_cache_size | `11GB` |
| max_connections | `300` |

### PostgreSQL - WAL

| Setting | Value |
|---------|-------|
| wal_buffers | `64MB` |
| wal_compression | `lz4` |
| max_wal_size | `32GB` |
| checkpoint_timeout | `30min` |
| synchronous_commit | `on` |
| commit_delay | `0` |

### PostgreSQL - Background Writer

| Setting | Value |
|---------|-------|
| bgwriter_delay | `10ms` |
| bgwriter_lru_maxpages | `500` |
| bgwriter_lru_multiplier | `4.0` |

### PostgreSQL - Parallel Query

| Setting | Value |
|---------|-------|
| max_worker_processes | `2` |
| max_parallel_workers | `2` |
| max_parallel_workers_per_gather | `2` |
| jit | `off` |

### OS Tuning

| Setting | Value |
|---------|-------|
| vm.nr_hugepages | `2191` |
| vm.swappiness | `1` |
| vm.dirty_background_ratio | `1` |
| vm.dirty_ratio | `4` |

### Block Device Tuning

| Device | read_ahead_kb | scheduler | nomerges |
|--------|---------------|-----------|----------|
| md0 (DATA) | `64` | `none` | `0` |
| md1 (WAL) | `4096` | `none` | `0` |

### Benchmark Config

| Setting | Value |
|---------|-------|
| pgbench_scale | `204` |
| pgbench_duration | `60` |
| pgbench_clients_heavy | `100` |

---

## Configuration Verification

### OS Memory

| Setting | Expected | Actual | Status |
|---------|----------|--------|--------|
| vm.swappiness | `1` | `1` | ✓ |
| vm.nr_hugepages | `2191` | `2200` | ✗ |
| vm.dirty_background_ratio | `1` | `1` | ✓ |
| vm.dirty_ratio | `4` | `4` | ✓ |
| vm.dirty_expire_centisecs | `200` | `200` | ✓ |
| vm.dirty_writeback_centisecs | `100` | `100` | ✓ |
| vm.overcommit_memory | `2` | `2` | ✓ |
| vm.overcommit_ratio | `80` | `80` | ✓ |
| vm.min_free_kbytes | `167772` | `167772` | ✓ |

### OS FileDesc

| Setting | Expected | Actual | Status |
|---------|----------|--------|--------|
| fs.file-max | `2097152` | `2097152` | ✓ |
| fs.aio-max-nr | `1048576` | `1048576` | ✓ |

### OS Network

| Setting | Expected | Actual | Status |
|---------|----------|--------|--------|
| net.core.somaxconn | `4096` | `4096` | ✓ |
| net.core.rmem_max | `16777216` | `16777216` | ✓ |
| net.core.wmem_max | `16777216` | `16777216` | ✓ |
| net.ipv4.tcp_tw_reuse | `1` | `1` | ✓ |
| net.ipv4.tcp_fin_timeout | `15` | `15` | ✓ |

### Block md0

| Setting | Expected | Actual | Status |
|---------|----------|--------|--------|
| read_ahead_kb | `64` | `64` | ✓ |
| rotational | `0` | `0` | ✓ |
| add_random | `0` | `0` | ✓ |
| nomerges | `0` | `0` | ✓ |
| max_sectors_kb | `256` | `256` | ✓ |

### Block md1

| Setting | Expected | Actual | Status |
|---------|----------|--------|--------|
| read_ahead_kb | `4096` | `4096` | ✓ |
| rotational | `0` | `0` | ✓ |
| add_random | `0` | `0` | ✓ |
| nomerges | `0` | `0` | ✓ |
| max_sectors_kb | `256` | `256` | ✓ |

### PG Memory

| Setting | Expected | Actual | Status |
|---------|----------|--------|--------|
| max_connections | `300` | `300` | ✓ |
| shared_buffers | `4GB` | `4GB` | ✓ |
| huge_pages | `try` | `try` | ✓ |
| work_mem | `16MB` | `16MB` | ✓ |
| maintenance_work_mem | `256MB` | `256MB` | ✓ |
| effective_cache_size | `11GB` | `11GB` | ✓ |

### PG DiskIO

| Setting | Expected | Actual | Status |
|---------|----------|--------|--------|
| random_page_cost | `1.1` | `1.1` | ✓ |
| effective_io_concurrency | `200` | `200` | ✓ |

### PG WAL

| Setting | Expected | Actual | Status |
|---------|----------|--------|--------|
| wal_compression | `lz4` | `lz4` | ✓ |
| wal_buffers | `64MB` | `64MB` | ✓ |
| wal_writer_delay | `10ms` | `10ms` | ✓ |
| max_wal_size | `32GB` | `32GB` | ✓ |
| checkpoint_timeout | `30min` | `30min` | ✓ |

### PG Sync

| Setting | Expected | Actual | Status |
|---------|----------|--------|--------|
| synchronous_commit | `on` | `on` | ✓ |
| commit_delay | `0` | `0` | ✓ |
| commit_siblings | `5` | `5` | ✓ |

### PG BGWriter

| Setting | Expected | Actual | Status |
|---------|----------|--------|--------|
| bgwriter_delay | `10ms` | `10ms` | ✓ |
| bgwriter_lru_maxpages | `500` | `500` | ✓ |
| bgwriter_lru_multiplier | `4.0` | `4` | ✓ |

### PG Autovac

| Setting | Expected | Actual | Status |
|---------|----------|--------|--------|
| autovacuum | `on` | `on` | ✓ |
| autovacuum_max_workers | `2` | `2` | ✓ |

### PG Parallel

| Setting | Expected | Actual | Status |
|---------|----------|--------|--------|
| max_worker_processes | `2` | `2` | ✓ |
| max_parallel_workers | `2` | `2` | ✓ |
| max_parallel_workers_per_gather | `2` | `2` | ✓ |
| jit | `off` | `off` | ✓ |

---

## System Configuration

```
=== INSTANCE ===

Linux ip-10-0-1-28 6.14.0-1018-aws #18~24.04.1-Ubuntu SMP Mon Nov 24 19:32:52 UTC 2025 aarch64 aarch64 aarch64 GNU/Linux
Architecture:                            aarch64
CPU(s):                                  2
Model name:                              Neoverse-V2
total        used        free      shared  buff/cache   available
Mem:            15Gi       5.1Gi       1.7Gi       2.4Mi       9.0Gi        10Gi
Swap:             0B          0B          0B

=== OS TUNING ===
vm.swappiness = 1
vm.dirty_ratio = 4
vm.dirty_background_ratio = 1
vm.dirty_expire_centisecs = 200
vm.dirty_writeback_centisecs = 100
always madvise [never]

=== HUGEPAGES ===
AnonHugePages:         0 kB
ShmemHugePages:        0 kB
FileHugePages:    309248 kB
HugePages_Total:    2200
HugePages_Free:       69
HugePages_Rsvd:        5
HugePages_Surp:        0

=== NETWORK ===
net.core.somaxconn = 4096
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15

=== DISK - RAID ===
Personalities : [raid10] 
md1 : active raid10 nvme9n1[6] nvme11n1[7] nvme15n1[1] nvme13n1[2] nvme12n1[0] nvme16n1[5] nvme10n1[3] nvme14n1[4]
      125759488 blocks super 1.2 256K chunks 2 near-copies [8/8] [UUUUUUUU]
      
md0 : active raid10 nvme6n1[3] nvme2n1[7] nvme3n1[5] nvme1n1[4] nvme7n1[2] nvme4n1[6] nvme5n1[1] nvme8n1[0]
      209580032 blocks super 1.2 64K chunks 2 near-copies [8/8] [UUUUUUUU]
      
unused devices: <none>
/dev/md0:
           Version : 1.2
     Creation Time : Sat Jan  3 08:26:08 2026
        Raid Level : raid10
        Array Size : 209580032 (199.87 GiB 214.61 GB)
     Used Dev Size : 52395008 (49.97 GiB 53.65 GB)
      Raid Devices : 8
     Total Devices : 8
       Persistence : Superblock is persistent

       Update Time : Mon Jan  5 12:50:25 2026
             State : clean 
    Active Devices : 8
   Working Devices : 8
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 64K

Consistency Policy : resync

              Name : ip-10-0-1-227:0
              UUID : ec94b08e:1ec1acd2:a24076ab:c0b61faa
            Events : 310

    Number   Major   Minor   RaidDevice State
       0     259        6        0      active sync set-A   /dev/nvme8n1
       1     259        4        1      active sync set-B   /dev/nvme5n1
       2     259        8        2      active sync set-A   /dev/nvme7n1
       3     259        5        3      active sync set-B   /dev/nvme6n1
       4     259        2        4      active sync set-A   /dev/nvme1n1
       5     259        1        5      active sync set-B   /dev/nvme3n1
       6     259        3        6      active sync set-A   /dev/nvme4n1
       7     259        7        7      active sync set-B   /dev/nvme2n1
/dev/md1:
           Version : 1.2
     Creation Time : Sat Jan  3 08:26:08 2026
        Raid Level : raid10
        Array Size : 125759488 (119.93 GiB 128.78 GB)
     Used Dev Size : 31439872 (29.98 GiB 32.19 GB)
      Raid Devices : 8
     Total Devices : 8
       Persistence : Superblock is persistent

       Update Time : Mon Jan  5 12:50:29 2026
             State : clean 
    Active Devices : 8
   Working Devices : 8
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 256K

Consistency Policy : resync

              Name : ip-10-0-1-227:1
              UUID : 4920b43f:4424608d:2e163255:f781c5ec
            Events : 22

    Number   Major   Minor   RaidDevice State
       0     259       13        0      active sync set-A   /dev/nvme12n1
       1     259       19        1      active sync set-B   /dev/nvme15n1
       2     259       18        2      active sync set-A   /dev/nvme13n1
       3     259        9        3      active sync set-B   /dev/nvme10n1
       4     259       11        4      active sync set-A   /dev/nvme14n1
       5     259       14        5      active sync set-B   /dev/nvme16n1
       6     259       10        6      active sync set-A   /dev/nvme9n1
       7     259       12        7      active sync set-B   /dev/nvme11n1

=== DISK - BLOCK TUNING ===
--- md0 ---
scheduler: 
read_ahead_kb: 64
nr_requests: 
--- md1 ---
scheduler: 
read_ahead_kb: 4096
nr_requests: 

=== DISK - MOUNT ===
/dev/md1 on /wal type xfs (rw,noatime,nodiratime,attr2,inode64,logbufs=8,logbsize=256k,sunit=512,swidth=2048,noquota)
/dev/md0 on /data type xfs (rw,noatime,nodiratime,attr2,inode64,allocsize=65536k,logbufs=8,logbsize=256k,sunit=128,swidth=512,noquota)
Filesystem      Size  Used Avail Use% Mounted on
/dev/md0        200G   28G  172G  14% /data
/dev/md1        120G   19G  101G  16% /wal

=== DISK - XFS ===
meta-data=/dev/md0               isize=512    agcount=16, agsize=3274688 blks
         =                       sectsz=4096  attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=1
         =                       reflink=1    bigtime=1 inobtcount=1 nrext64=0
data     =                       bsize=4096   blocks=52395008, imaxpct=25
         =                       sunit=16     swidth=64 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=25583, version=2
         =                       sectsz=4096  sunit=1 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
meta-data=/dev/md1               isize=512    agcount=8, agsize=3929984 blks
         =                       sectsz=4096  attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=1
         =                       reflink=1    bigtime=1 inobtcount=1 nrext64=0
data     =                       bsize=4096   blocks=31439872, imaxpct=25
         =                       sunit=64     swidth=256 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=16384, version=2
         =                       sectsz=4096  sunit=1 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

=== POSTGRESQL CONFIG ===
effective_cache_size | 1441792 | 8kB
 huge_pages           | try     | 
 max_connections      | 300     | 
 max_wal_size         | 32768   | MB
 shared_buffers       | 524288  | 8kB
 wal_buffers          | 8192    | 8kB
 work_mem             | 16384   | kB
```

---

## Benchmark Output

```
pgbench (16.11 (Ubuntu 16.11-1.pgdg24.04+1))
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 204
query mode: simple
number of clients: 50
number of threads: 2
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 290646
number of failed transactions: 0 (0.000%)
latency average = 10.306 ms
latency stddev = 3.401 ms
initial connection time = 40.526 ms
tps = 4844.467372 (without initial connection time)
starting vacuum...end.
progress: 5.0 s, 4646.5 tps, lat 10.646 ms stddev 3.881, 0 failed
progress: 10.0 s, 4782.4 tps, lat 10.434 ms stddev 3.387, 0 failed
progress: 15.0 s, 4880.2 tps, lat 10.240 ms stddev 3.253, 0 failed
progress: 20.0 s, 4880.4 tps, lat 10.234 ms stddev 3.441, 0 failed
progress: 25.0 s, 4922.2 tps, lat 10.150 ms stddev 3.321, 0 failed
progress: 30.0 s, 4891.2 tps, lat 10.202 ms stddev 3.387, 0 failed
progress: 35.0 s, 4925.4 tps, lat 10.137 ms stddev 3.264, 0 failed
progress: 40.0 s, 4858.8 tps, lat 10.282 ms stddev 3.349, 0 failed
progress: 45.0 s, 4875.2 tps, lat 10.245 ms stddev 3.415, 0 failed
progress: 50.0 s, 4719.5 tps, lat 10.587 ms stddev 3.433, 0 failed
progress: 55.0 s, 4812.8 tps, lat 10.379 ms stddev 3.298, 0 failed
progress: 60.0 s, 4924.5 tps, lat 10.148 ms stddev 3.263, 0 failed

```

---

## Diagnostics

### iostat

```
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0           1214.68  15124.92     0.00   0.00    2.74    12.45  490.86   9880.95     0.00   0.00    2.01    20.13    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    4.31  43.40
md1              0.17      3.13     0.00   0.00    0.94    18.05  124.28   4974.76     0.00   0.00    1.26    40.03    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.16  10.65
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0             38.00    396.00     0.00   0.00    2.66    10.42  384.00   3072.00     0.00   0.00    0.94     8.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.46   9.80
md1              0.00      0.00     0.00   0.00    0.00     0.00    1.00      8.00     0.00   0.00    1.00     8.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.10
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00  576.00   4608.00     0.00   0.00    0.97     8.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.56   1.20
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              7.00     56.00     0.00   0.00    0.71     8.00  838.00   6968.00     0.00   0.00    0.92     8.32    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.78   4.30
md1              0.00      0.00     0.00   0.00    0.00     0.00  447.00  18800.00     0.00   0.00    1.20    42.06    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.54  47.60
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00 1472.00  11776.00     0.00   0.00    0.96     8.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    1.41   6.60
md1              0.00      0.00     0.00   0.00    0.00     0.00  494.00  19904.00     0.00   0.00    1.17    40.29    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.58  52.10
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00  640.00   5920.00     0.00   0.00    0.99     9.25    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.63   1.90
md1              0.00      0.00     0.00   0.00    0.00     0.00  463.00  19016.00     0.00   0.00    1.23    41.07    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.57  51.30
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00  383.00   3072.00     0.00   0.00    0.94     8.02    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.36   1.40
md1              0.00      0.00     0.00   0.00    0.00     0.00  481.00  18512.00     0.00   0.00    1.20    38.49    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.58  52.00
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00  400.00   3856.00     0.00   0.00    1.02     9.64    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.41   2.00
md1              0.00      0.00     0.00   0.00    0.00     0.00  466.00  17560.00     0.00   0.00    1.18    37.68    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.55  50.00
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00  320.00   2560.00     0.00   0.00    0.91     8.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.29   1.20
md1              0.00      0.00     0.00   0.00    0.00     0.00  472.00  17608.00     0.00   0.00    1.18    37.31    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.56  50.00
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00  400.00   3848.00     0.00   0.00    0.97     9.62    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.39   2.70
md1              0.00      0.00     0.00   0.00    0.00     0.00  474.00  17024.00     0.00   0.00    1.18    35.92    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.56  51.00
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00  320.00   2560.00     0.00   0.00    0.99     8.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.32   1.40
md1              0.00      0.00     0.00   0.00    0.00     0.00  481.00  16480.00     0.00   0.00    1.15    34.26    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.55  50.70
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00  337.00   3384.00     0.00   0.00    0.98    10.04    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.33   1.90
md1              0.00      0.00     0.00   0.00    0.00     0.00  488.00  15856.00     0.00   0.00    1.16    32.49    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.56  52.20
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00  320.00   2560.00     0.00   0.00    0.99     8.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.32   2.00
md1              0.00      0.00     0.00   0.00    0.00     0.00  470.00  15592.00     0.00   0.00    1.16    33.17    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.55  50.10
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00  271.00   2800.00     0.00   0.00    0.99    10.33    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.27   1.30
md1              0.00      0.00     0.00   0.00    0.00     0.00  480.00  15152.00     0.00   0.00    1.15    31.57    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.55  50.70
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00  256.00   2048.00     0.00   0.00    0.97     8.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.25   1.50
md1              0.00      0.00     0.00   0.00    0.00     0.00  498.00  14920.00     0.00   0.00    1.14    29.96    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.57  53.00
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00  334.00   3280.00     0.00   0.00    0.99     9.82    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.33   1.60
md1              0.00      0.00     0.00   0.00    0.00     0.00  480.00  14576.00     0.00   0.00    1.12    30.37    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.54  49.80
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00  256.00   2048.00     0.00   0.00    0.94     8.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.24   1.90
md1              0.00      0.00     0.00   0.00    0.00     0.00  503.00  14068.00     0.00   0.00    1.10    27.97    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.55  50.30

... (87 lines omitted) ...

Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00  348.00   3904.00     0.00   0.00    1.00    11.22    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.35   1.70
md1              0.00      0.00     0.00   0.00    0.00     0.00  484.00   8424.00     0.00   0.00    1.02    17.40    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.49  47.70
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00  307.00   2560.00     0.00   0.00    0.94     8.34    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.29   1.40
md1              0.00      0.00     0.00   0.00    0.00     0.00  477.00   8384.00     0.00   0.00    1.01    17.58    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.48  46.70
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00   28.00    968.00     0.00   0.00    1.00    34.57    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.03   0.10
md1              0.00      0.00     0.00   0.00    0.00     0.00  499.00   8368.00     0.00   0.00    1.01    16.77    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.50  48.50
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              1.00      8.00     0.00   0.00    1.00     8.00   56.00    488.00     0.00   0.00    1.00     8.71    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.06   0.70
md1              0.00      0.00     0.00   0.00    0.00     0.00  490.00   7976.00     0.00   0.00    1.02    16.28    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.50  48.50
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00   90.00   1784.00     0.00   0.00    1.27    19.82    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.11   0.40
md1              0.00      0.00     0.00   0.00    0.00     0.00  508.00   8216.00     0.00   0.00    0.99    16.17    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.51  49.00
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00   64.00    512.00     0.00   0.00    0.77     8.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.05   0.70
md1              0.00      0.00     0.00   0.00    0.00     0.00  483.00   8016.00     0.00   0.00    1.01    16.60    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.49  47.30
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00   25.00    600.00     0.00   0.00    1.04    24.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.03   0.20
md1              0.00      0.00     0.00   0.00    0.00     0.00  490.00   7872.00     0.00   0.00    0.99    16.07    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.48  47.00
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00   53.00    432.00     0.00   0.00    1.06     8.15    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.06   0.70
md1              0.00      0.00     0.00   0.00    0.00     0.00  479.00   7896.00     0.00   0.00    1.01    16.48    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.48  46.60
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00   91.00   1776.00     0.00   0.00    1.34    19.52    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.12   1.50
md1              0.00      0.00     0.00   0.00    0.00     0.00  500.00   7952.00     0.00   0.00    1.01    15.90    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.51  49.10
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00   65.00    568.00     0.00   0.00    0.75     8.74    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.05   0.70
md1              0.00      0.00     0.00   0.00    0.00     0.00  482.00   7592.00     0.00   0.00    0.99    15.75    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.48  46.30
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00   27.00    544.00     0.00   0.00    1.33    20.15    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.04   0.20
md1              0.00      0.00     0.00   0.00    0.00     0.00  503.00   7944.00     0.00   0.00    0.99    15.79    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.50  48.30
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00   56.00   1064.00     0.00   0.00    1.16    19.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.07   0.30
md1              0.00      0.00     0.00   0.00    0.00     0.00  479.00   7480.00     0.00   0.00    0.99    15.62    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.48  46.20
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00   74.00    968.00     0.00   0.00    1.01    13.08    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.07   0.40
md1              0.00      0.00     0.00   0.00    0.00     0.00  481.00   7584.00     0.00   0.00    1.02    15.77    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.49  47.90
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00   11.88     95.05     0.00   0.00    1.00     8.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.01   0.10
md1              0.00      0.00     0.00   0.00    0.00     0.00  495.05   7643.56     0.00   0.00    1.00    15.44    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.49  48.12
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00   76.00   1648.00     0.00   0.00    1.16    21.68    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.09   0.40
md1              0.00      0.00     0.00   0.00    0.00     0.00  489.00   7744.00     0.00   0.00    0.99    15.84    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.48  46.80
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md0              0.00      0.00     0.00   0.00    0.00     0.00   63.00    552.00     0.00   0.00    0.86     8.76    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.05   0.50
md1              0.00      0.00     0.00   0.00    0.00     0.00  499.00   7624.00     0.00   0.00    0.99    15.28    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.49  48.00
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
md1              0.00      0.00     
```

### mpstat

```
Linux 6.14.0-1018-aws (ip-10-0-1-28) 	01/05/26 	_aarch64_	(2 CPU)

12:51:14     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:51:15     all    2.01    0.00    1.51    5.03    0.00    0.00    0.00    0.00    0.00   91.46
12:51:15       0    2.02    0.00    1.01    1.01    0.00    0.00    0.00    0.00    0.00   95.96
12:51:15       1    2.00    0.00    2.00    9.00    0.00    0.00    0.00    0.00    0.00   87.00

12:51:15     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:51:16     all    1.00    0.00    1.00    0.00    0.00    0.00    0.00    0.00    0.00   98.00
12:51:16       0    1.98    0.00    0.99    0.00    0.00    0.00    0.00    0.00    0.00   97.03
12:51:16       1    0.00    0.00    1.01    0.00    0.00    0.00    0.00    0.00    0.00   98.99

12:51:16     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:51:17     all   59.00    0.00   38.00    0.50    0.00    0.00    0.00    0.00    0.00    2.50
12:51:17       0   68.00    0.00   30.00    1.00    0.00    0.00    0.00    0.00    0.00    1.00
12:51:17       1   50.00    0.00   46.00    0.00    0.00    0.00    0.00    0.00    0.00    4.00

12:51:17     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:51:18     all   60.80    0.00   38.69    0.00    0.00    0.00    0.00    0.00    0.00    0.50
12:51:18       0   54.00    0.00   45.00    0.00    0.00    0.00    0.00    0.00    0.00    1.00
12:51:18       1   67.68    0.00   32.32    0.00    0.00    0.00    0.00    0.00    0.00    0.00

12:51:18     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:51:19     all   64.00    0.00   35.00    0.50    0.00    0.00    0.00    0.00    0.00    0.50
12:51:19       0   64.65    0.00   35.35    0.00    0.00    0.00    0.00    0.00    0.00    0.00
12:51:19       1   63.37    0.00   34.65    0.99    0.00    0.00    0.00    0.00    0.00    0.99

12:51:19     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:51:20     all   62.81    0.00   36.68    0.50    0.00    0.00    0.00    0.00    0.00    0.00
12:51:20       0   69.00    0.00   30.00    1.00    0.00    0.00    0.00    0.00    0.00    0.00
12:51:20       1   56.57    0.00   43.43    0.00    0.00    0.00    0.00    0.00    0.00    0.00

12:51:20     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:51:21     all   61.50    0.00   37.00    0.50    0.00    0.00    0.00    0.00    0.00    1.00
12:51:21       0   61.00    0.00   38.00    0.00    0.00    0.00    0.00    0.00    0.00    1.00
12:51:21       1   62.00    0.00   36.00    1.00    0.00    0.00    0.00    0.00    0.00    1.00

12:51:21     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:51:22     all   63.00    0.00   36.00    0.50    0.00    0.00    0.00    0.00    0.00    0.50
12:51:22       0   54.00    0.00   44.00    1.00    0.00    0.00    0.00    0.00    0.00    1.00
12:51:22       1   72.00    0.00   28.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00

12:51:22     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:51:23     all   64.32    0.00   35.68    0.00    0.00    0.00    0.00    0.00    0.00    0.00
12:51:23       0   55.56    0.00   44.44    0.00    0.00    0.00    0.00    0.00    0.00    0.00
12:51:23       1   73.00    0.00   27.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00

12:51:23     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:51:24     all   61.88    0.00   36.63    0.50    0.00    0.00    0.00    0.00    0.00    0.99
12:51:24       0   53.47    0.00   44.55    0.99    0.00    0.00    0.00    0.00    0.00    0.99

... (227 lines omitted) ...

12:52:09     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:52:10     all   61.88    0.00   37.62    0.00    0.00    0.00    0.00    0.00    0.00    0.50
12:52:10       0   63.73    0.00   35.29    0.00    0.00    0.00    0.00    0.00    0.00    0.98
12:52:10       1   60.00    0.00   40.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00

12:52:10     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:52:11     all   60.80    0.00   38.69    0.00    0.00    0.00    0.00    0.00    0.00    0.50
12:52:11       0   67.68    0.00   32.32    0.00    0.00    0.00    0.00    0.00    0.00    0.00
12:52:11       1   54.00    0.00   45.00    0.00    0.00    0.00    0.00    0.00    0.00    1.00

12:52:11     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:52:12     all   62.00    0.00   38.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
12:52:12       0   70.00    0.00   30.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
12:52:12       1   54.00    0.00   46.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00

12:52:12     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:52:13     all   62.31    0.00   37.19    0.50    0.00    0.00    0.00    0.00    0.00    0.00
12:52:13       0   71.00    0.00   29.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
12:52:13       1   53.54    0.00   45.45    1.01    0.00    0.00    0.00    0.00    0.00    0.00

12:52:13     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:52:14     all   62.38    0.00   36.63    0.50    0.00    0.00    0.00    0.00    0.00    0.50
12:52:14       0   70.30    0.00   28.71    0.99    0.00    0.00    0.00    0.00    0.00    0.00
12:52:14       1   54.46    0.00   44.55    0.00    0.00    0.00    0.00    0.00    0.00    0.99

12:52:14     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:52:15     all   62.63    0.00   37.37    0.00    0.00    0.00    0.00    0.00    0.00    0.00
12:52:15       0   64.65    0.00   35.35    0.00    0.00    0.00    0.00    0.00    0.00    0.00
12:52:15       1   60.61    0.00   39.39    0.00    0.00    0.00    0.00    0.00    0.00    0.00

12:52:15     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:52:16     all   61.11    0.00   38.38    0.00    0.00    0.00    0.00    0.00    0.00    0.51
12:52:16       0   53.54    0.00   45.45    0.00    0.00    0.00    0.00    0.00    0.00    1.01
12:52:16       1   68.69    0.00   31.31    0.00    0.00    0.00    0.00    0.00    0.00    0.00

12:52:16     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:52:17     all    3.98    0.00    5.47    0.00    0.00    0.00    0.00    0.00    0.00   90.55
12:52:17       0    4.00    0.00    6.00    0.00    0.00    0.00    0.00    0.00    0.00   90.00
12:52:17       1    3.96    0.00    4.95    0.00    0.00    0.00    0.00    0.00    0.00   91.09

12:52:17     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:52:18     all    1.00    0.00    0.50    0.50    0.00    0.00    0.00    0.00    0.00   98.01
12:52:18       0    1.98    0.00    0.99    0.00    0.00    0.00    0.00    0.00    0.00   97.03
12:52:18       1    0.00    0.00    0.00    1.00    0.00    0.00    0.00    0.00    0.00   99.00

12:52:18     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
12:52:19     all    0.50    0.00    1.01    0.00    0.00    0.00    0.00    0.00    0.00   98.49
12:52:19       0    1.00    0.00    2.00    0.00    0.00    0.00    0.00    0.00    0.00   97.00
12:52:19       1    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00

```

### pg_wait_events

```
=== 12:51:14 ===
 IO   | DataFileRead |   1

=== 12:51:15 ===

=== 12:51:16 ===
 Lock   | extend         |  31
 LWLock | WALWrite       |  12
 Lock   | transactionid  |   5
 IO     | DataFileExtend |   1
 IO     | WALSync        |   1

=== 12:51:17 ===
 LWLock | WALWrite      |  11
 Lock   | transactionid |   5
 IO     | WALSync       |   1

=== 12:51:18 ===
 LWLock | WALWrite      |  19
 Lock   | transactionid |   3
 CPU    | Running       |   2
 IO     | WALSync       |   1

=== 12:51:19 ===
 CPU    | Running       |   5
 LWLock | WALWrite      |   4
 Lock   | transactionid |   1

=== 12:51:20 ===
 LWLock | WALWrite      |  25
 CPU    | Running       |  11
 Lock   | transactionid |   3
 IO     | WALSync       |   1

=== 12:51:21 ===
 LWLock | WALWrite      |  12
 Lock   | transactionid |   8
 CPU    | Running       |   1
 Client | ClientRead    |   1

=== 12:51:22 ===
 LWLock | WALWrite      |  22
 Lock   | transactionid |   4
 CPU    | Running       |   2
 IO     | WALSync       |   1
 Lock   | tuple         |   1

=== 12:51:23 ===
 Client | ClientRead    |   1
 IO     | WALSync       |   1

... (250 lines omitted) ...

 LWLock | WALWrite      |  31
 Lock   | transactionid |   3
 CPU    | Running       |   1
 IO     | WALSync       |   1

=== 12:52:09 ===
 LWLock | WALWrite      |  21
 CPU    | Running       |   5
 Lock   | transactionid |   3
 IO     | WALSync       |   1
 LWLock | BufferContent |   1

=== 12:52:10 ===
 LWLock | WALWrite      |  30
 Lock   | transactionid |   4
 Client | ClientRead    |   1
 IO     | WALSync       |   1
 Lock   | tuple         |   1

=== 12:52:11 ===
 CPU    | Running       |   9
 LWLock | WALWrite      |   8
 Client | ClientRead    |   4
 Lock   | transactionid |   1

=== 12:52:12 ===
 LWLock | WALWrite      |   4
 Lock   | transactionid |   3
 CPU    | Running       |   2
 IO     | WALSync       |   1
 Lock   | tuple         |   1

=== 12:52:14 ===
 LWLock | WALWrite      |   6
 Lock   | transactionid |   2
 CPU    | Running       |   1
 IO     | WALSync       |   1

=== 12:52:15 ===
 LWLock | WALWrite      |  16
 Lock   | transactionid |   5
 IO     | WALSync       |   1

=== 12:52:16 ===

=== 12:52:17 ===

=== 12:52:18 ===


```

### pg_stats

```
Time,HitRatio,TPS,Active,WaitLock,Deadlock,WalBytes
12:51:14,98.36,6,1,0,0,9259537594
12:51:19,98.84,16,38,3,0,9310234999
12:51:24,99.42,30,7,3,0,9382935970
12:51:29,99.61,42,32,4,0,9443444098
12:51:34,99.69,52,31,6,0,9494424690
12:51:39,99.75,64,43,3,0,9537141279
12:51:44,99.80,76,4,0,0,9573927845
12:51:49,99.82,86,11,1,0,9606326367
12:51:54,99.84,98,22,4,0,9634814662
12:52:00,99.86,110,22,1,0,9660593347
12:52:05,99.87,120,26,1,0,9683912943
12:52:10,99.89,132,24,2,0,9705366953

```

---
