# Benchmark: [POSTGRES DISK] High Concurrency Stress - Context Switch Storm

**Date:** 2026-01-03 17:08:02
**Scenario:** Context Switch Storm - 1000 Clients fighting for 8 Cores

---

## Target Disk

| Property | Value |
|----------|-------|
| **Name** | **POSTGRES** |
| **Mount Point** | `/data,/wal` |
| **Device** | `/dev/md0,/dev/md1` |
| **Volumes** | `nvme1n1, nvme2n1, nvme3n1, nvme4n1, nvme5n1, nvme6n1, nvme7n1, nvme8n1, nvme9n1, nvme10n1, nvme11n1, nvme12n1, nvme13n1, nvme14n1, nvme15n1, nvme16n1, md0, md1` |

---

## System Configuration

```
=== INSTANCE ===

Linux ip-10-0-1-227 6.14.0-1018-aws #18~24.04.1-Ubuntu SMP Mon Nov 24 19:32:52 UTC 2025 aarch64 aarch64 aarch64 GNU/Linux
Architecture:                            aarch64
CPU(s):                                  8
Model name:                              Neoverse-V2
total        used        free      shared  buff/cache   available
Mem:            15Gi       5.0Gi       391Mi       4.2Gi        14Gi        10Gi
Swap:             0B          0B          0B

=== OS TUNING ===
vm.swappiness = 1
vm.dirty_ratio = 4
vm.dirty_background_ratio = 1
vm.dirty_expire_centisecs = 200
vm.dirty_writeback_centisecs = 100
always madvise [never]

=== NETWORK ===
net.core.somaxconn = 4096
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15

=== DISK - RAID ===
Personalities : [raid10] 
md1 : active raid10 nvme16n1[7] nvme14n1[6] nvme13n1[5] nvme10n1[4] nvme7n1[3] nvme6n1[2] nvme4n1[1] nvme1n1[0]
      125759488 blocks super 1.2 256K chunks 2 near-copies [8/8] [UUUUUUUU]
      
md0 : active raid10 nvme15n1[7] nvme12n1[6] nvme11n1[5] nvme9n1[4] nvme8n1[3] nvme5n1[2] nvme3n1[1] nvme2n1[0]
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

       Update Time : Sat Jan  3 17:07:54 2026
             State : clean 
    Active Devices : 8
   Working Devices : 8
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 64K

Consistency Policy : resync

              Name : ip-10-0-1-227:0  (local to host ip-10-0-1-227)
              UUID : ec94b08e:1ec1acd2:a24076ab:c0b61faa
            Events : 19

    Number   Major   Minor   RaidDevice State
       0     259        5        0      active sync set-A   /dev/nvme2n1
       1     259        6        1      active sync set-B   /dev/nvme3n1
       2     259        8        2      active sync set-A   /dev/nvme5n1
       3     259       11        3      active sync set-B   /dev/nvme8n1
       4     259       12        4      active sync set-A   /dev/nvme9n1
       5     259       14        5      active sync set-B   /dev/nvme11n1
       6     259       15        6      active sync set-A   /dev/nvme12n1
       7     259       18        7      active sync set-B   /dev/nvme15n1
/dev/md1:
           Version : 1.2
     Creation Time : Sat Jan  3 08:26:08 2026
        Raid Level : raid10
        Array Size : 125759488 (119.93 GiB 128.78 GB)
     Used Dev Size : 31439872 (29.98 GiB 32.19 GB)
      Raid Devices : 8
     Total Devices : 8
       Persistence : Superblock is persistent

       Update Time : Sat Jan  3 17:07:51 2026
             State : clean 
    Active Devices : 8
   Working Devices : 8
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 256K

Consistency Policy : resync

              Name : ip-10-0-1-227:1  (local to host ip-10-0-1-227)
              UUID : 4920b43f:4424608d:2e163255:f781c5ec
            Events : 19

    Number   Major   Minor   RaidDevice State
       0     259        4        0      active sync set-A   /dev/nvme1n1
       1     259        7        1      active sync set-B   /dev/nvme4n1
       2     259        9        2      active sync set-A   /dev/nvme6n1
       3     259       10        3      active sync set-B   /dev/nvme7n1
       4     259       13        4      active sync set-A   /dev/nvme10n1
       5     259       16        5      active sync set-B   /dev/nvme13n1
       6     259       17        6      active sync set-A   /dev/nvme14n1
       7     259       19        7      active sync set-B   /dev/nvme16n1

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
/dev/md0 on /data type xfs (rw,noatime,nodiratime,attr2,inode64,allocsize=65536k,logbufs=8,logbsize=256k,sunit=128,swidth=512,noquota)
/dev/md1 on /wal type xfs (rw,noatime,nodiratime,attr2,inode64,logbufs=8,logbsize=256k,sunit=512,swidth=2048,noquota)
Filesystem      Size  Used Avail Use% Mounted on
/dev/md0        200G   40G  161G  20% /data
/dev/md1        120G   27G   94G  22% /wal

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
```

---

## Command 1: Begin:pg_stat_reset

### Command
```bash
sudo -u postgres psql -c 'SELECT pg_stat_reset();'
```

### Output
```
 pg_stat_reset 
---------------
 
(1 row)


```

---

## Command 2: pgbench

### Command
```bash
sudo -u postgres pgbench -S -c 1000 -j 4 -T 60 -P 5 pgbench
```

### Output
```
pgbench (16.11 (Ubuntu 16.11-1.pgdg24.04+1))
starting vacuum...end.
pgbench: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  sorry, too many clients already
pgbench: error: could not create connection for client 824

```

---

## Command 3: vmstat

### Command
```bash
vmstat 1 70
```

### Output
```
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 0  1      0 399940  25752 15128364    0    0 10617 15096 5108    9  1  1 96  3  0  0
 0  0      0 400388  25752 15128680    0    0   104     0  490  245  0  0 100  0  0  0
 1  0      0 409796  25752 15128680    0    0     0   472  612  371  0  0 100  0  0  0
 0  0      0 797800  25752 14819488    0    0     4   192 3441 3030  2 12 85  0  0  0
 0  0      0 800392  25752 14819488    0    0     0     0  621  290  0  0 100  0  0  0

```

---

## Command 4: pg_wait_events

### Command
```bash
bash -c 'for i in $(seq 1 70); do echo "=== $(date '"'"'+%H:%M:%S'"'"') ==="; sudo -u postgres psql -t -c "SELECT coalesce(wait_event_type,'"'"'CPU'"'"') as type, coalesce(wait_event,'"'"'Running'"'"') as event, count(*) as cnt FROM pg_stat_activity WHERE state='"'"'active'"'"' AND pid<>pg_backend_pid() GROUP BY 1,2 ORDER BY 3 DESC LIMIT 10"; sleep 1; done'
```

### Output
```
=== 17:07:58 ===

=== 17:07:59 ===

=== 17:08:00 ===

=== 17:08:01 ===

=== 17:08:02 ===


```

---

## Command 5: End:pg_locks

### Command
```bash
sudo -u postgres psql -c 'SELECT mode, count(*) FROM pg_locks GROUP BY 1 ORDER BY 2 DESC'
```

### Output
```
      mode       | count 
-----------------+-------
 ExclusiveLock   |     1
 AccessShareLock |     1
(2 rows)


```

---
