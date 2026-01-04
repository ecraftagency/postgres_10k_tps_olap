# Benchmark: [POSTGRES DISK] pgbench TPC-B - PostgreSQL OLTP

**Date:** 2026-01-04 08:23:43
**Scenario:** PostgreSQL OLTP - 100 clients, TPC-B like workload with full monitoring

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

Linux ip-10-0-1-171 6.14.0-1018-aws #18~24.04.1-Ubuntu SMP Mon Nov 24 19:32:52 UTC 2025 aarch64 aarch64 aarch64 GNU/Linux
Architecture:                            aarch64
CPU(s):                                  32
Model name:                              Neoverse-V2
total        used        free      shared  buff/cache   available
Mem:            61Gi        24Gi       5.7Gi       2.6Mi        33Gi        37Gi
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
md1 : active raid10 nvme9n1[6] nvme13n1[2] nvme15n1[1] nvme11n1[7] nvme14n1[4] nvme12n1[0] nvme10n1[3] nvme16n1[5]
      125759488 blocks super 1.2 256K chunks 2 near-copies [8/8] [UUUUUUUU]
      
md0 : active raid10 nvme0n1[4] nvme4n1[6] nvme7n1[2] nvme6n1[3] nvme3n1[5] nvme2n1[7] nvme8n1[0] nvme5n1[1]
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

       Update Time : Sun Jan  4 08:21:24 2026
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
            Events : 292

    Number   Major   Minor   RaidDevice State
       0     259        8        0      active sync set-A   /dev/nvme8n1
       1     259        2        1      active sync set-B   /dev/nvme5n1
       2     259        7        2      active sync set-A   /dev/nvme7n1
       3     259        6        3      active sync set-B   /dev/nvme6n1
       4     259        3        4      active sync set-A   /dev/nvme0n1
       5     259        5        5      active sync set-B   /dev/nvme3n1
       6     259        1        6      active sync set-A   /dev/nvme4n1
       7     259        4        7      active sync set-B   /dev/nvme2n1
/dev/md1:
           Version : 1.2
     Creation Time : Sat Jan  3 08:26:08 2026
        Raid Level : raid10
        Array Size : 125759488 (119.93 GiB 128.78 GB)
     Used Dev Size : 31439872 (29.98 GiB 32.19 GB)
      Raid Devices : 8
     Total Devices : 8
       Persistence : Superblock is persistent

       Update Time : Sun Jan  4 08:21:32 2026
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
            Events : 19

    Number   Major   Minor   RaidDevice State
       0     259       12        0      active sync set-A   /dev/nvme12n1
       1     259       18        1      active sync set-B   /dev/nvme15n1
       2     259       15        2      active sync set-A   /dev/nvme13n1
       3     259       14        3      active sync set-B   /dev/nvme10n1
       4     259       17        4      active sync set-A   /dev/nvme14n1
       5     259       19        5      active sync set-B   /dev/nvme16n1
       6     259       16        6      active sync set-A   /dev/nvme9n1
       7     259       13        7      active sync set-B   /dev/nvme11n1

=== DISK - BLOCK TUNING ===
--- md0 ---
scheduler: 
read_ahead_kb: 512
nr_requests: 
--- md1 ---
scheduler: 
read_ahead_kb: 4096
nr_requests: 

=== DISK - MOUNT ===
/dev/md1 on /wal type xfs (rw,noatime,nodiratime,attr2,inode64,logbufs=8,logbsize=256k,sunit=512,swidth=2048,noquota)
/dev/md0 on /data type xfs (rw,noatime,nodiratime,attr2,inode64,allocsize=65536k,logbufs=8,logbsize=256k,sunit=128,swidth=512,noquota)
Filesystem      Size  Used Avail Use% Mounted on
/dev/md0        200G   44G  157G  22% /data
/dev/md1        120G   31G   90G  26% /wal

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

## Command 1: Begin:sysctl_swappiness

### Command
```bash
sysctl -w vm.swappiness=1
```

### Output
```
vm.swappiness = 1

```

---

## Command 2: Begin:sysctl_dirty_background

### Command
```bash
sysctl -w vm.dirty_background_ratio=1
```

### Output
```
vm.dirty_background_ratio = 1

```

---

## Command 3: Begin:sysctl_dirty_ratio

### Command
```bash
sysctl -w vm.dirty_ratio=4
```

### Output
```
vm.dirty_ratio = 4

```

---

## Command 4: Begin:sysctl_dirty_expire

### Command
```bash
sysctl -w vm.dirty_expire_centisecs=200
```

### Output
```
vm.dirty_expire_centisecs = 200

```

---

## Command 5: Begin:sysctl_dirty_writeback

### Command
```bash
sysctl -w vm.dirty_writeback_centisecs=100
```

### Output
```
vm.dirty_writeback_centisecs = 100

```

---

## Command 6: Begin:pg_stat_reset

### Command
```bash
sudo -u postgres psql -c 'SELECT pg_stat_reset(); SELECT pg_stat_reset_shared('"'"'bgwriter'"'"');'
```

### Output
```
 pg_stat_reset 
---------------
 
(1 row)

 pg_stat_reset_shared 
----------------------
 
(1 row)


```

---

## Command 7: pgbench

### Command
```bash
sudo -u postgres pgbench -c 100 -j 32 -T 120 -P 5 -b tpcb-like pgbench
```

### Output
```
pgbench (16.11 (Ubuntu 16.11-1.pgdg24.04+1))
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1374
query mode: simple
number of clients: 100
number of threads: 32
maximum number of tries: 1
duration: 120 s
number of transactions actually processed: 4889043
number of failed transactions: 0 (0.000%)
latency average = 2.452 ms
latency stddev = 0.759 ms
initial connection time = 39.400 ms
tps = 40751.945722 (without initial connection time)
starting vacuum...end.
progress: 5.0 s, 39220.1 tps, lat 2.528 ms stddev 0.462, 0 failed
progress: 10.0 s, 39769.2 tps, lat 2.513 ms stddev 0.451, 0 failed
progress: 15.0 s, 39927.8 tps, lat 2.503 ms stddev 0.454, 0 failed
progress: 20.0 s, 40026.6 tps, lat 2.497 ms stddev 0.473, 0 failed
progress: 25.0 s, 40125.2 tps, lat 2.491 ms stddev 0.454, 0 failed
progress: 30.0 s, 40359.6 tps, lat 2.476 ms stddev 0.469, 0 failed
progress: 35.0 s, 40323.6 tps, lat 2.479 ms stddev 0.466, 0 failed
progress: 40.0 s, 40500.6 tps, lat 2.468 ms stddev 0.465, 0 failed
progress: 45.0 s, 40582.0 tps, lat 2.463 ms stddev 0.476, 0 failed
progress: 50.0 s, 40755.0 tps, lat 2.452 ms stddev 0.446, 0 failed
progress: 55.0 s, 40727.2 tps, lat 2.454 ms stddev 0.456, 0 failed
progress: 60.0 s, 40949.4 tps, lat 2.441 ms stddev 0.446, 0 failed
progress: 65.0 s, 40950.7 tps, lat 2.440 ms stddev 0.448, 0 failed
progress: 70.0 s, 41157.6 tps, lat 2.428 ms stddev 0.444, 0 failed
progress: 75.0 s, 41275.0 tps, lat 2.421 ms stddev 0.430, 0 failed
progress: 80.0 s, 41101.0 tps, lat 2.432 ms stddev 0.482, 0 failed
progress: 85.0 s, 41285.4 tps, lat 2.421 ms stddev 0.455, 0 failed
progress: 90.0 s, 41267.6 tps, lat 2.422 ms stddev 0.467, 0 failed
progress: 95.0 s, 40474.2 tps, lat 2.469 ms stddev 2.329, 0 failed
progress: 100.0 s, 40748.0 tps, lat 2.453 ms stddev 1.827, 0 failed
progress: 105.0 s, 41539.0 tps, lat 2.406 ms stddev 0.569, 0 failed
progress: 110.0 s, 41583.6 tps, lat 2.403 ms stddev 0.609, 0 failed
progress: 115.0 s, 41647.2 tps, lat 2.400 ms stddev 0.629, 0 failed

```

---

## Command 8: meminfo

### Command
```bash
bash -c 'for i in $(seq 1 130); do date '"'"'+%H:%M:%S'"'"'; grep -E '"'"'Dirty|Writeback'"'"' /proc/meminfo; echo '"'"'---'"'"'; sleep 1; done'
```

### Output
```
08:21:39
Dirty:               340 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:21:40
Dirty:               516 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:21:41
Dirty:               160 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:21:42
Dirty:              1884 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:21:43
Dirty:              2648 kB
Writeback:           256 kB
WritebackTmp:          0 kB
---
08:21:44
Dirty:              1260 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:21:45
Dirty:              2304 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:21:46
Dirty:              3408 kB
Writeback:           744 kB
WritebackTmp:          0 kB
---
08:21:47
Dirty:              1300 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:21:48
Dirty:              1764 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:21:49
Dirty:              1904 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:21:50
Dirty:              2772 kB
Writeback:           256 kB
WritebackTmp:          0 kB
---
08:21:51
Dirty:              1236 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:21:52
Dirty:              2828 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:21:53
Dirty:              1696 kB
Writeback:           256 kB
WritebackTmp:          0 kB
---
08:21:54
Dirty:              2048 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:21:55
Dirty:              2432 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:21:56
Dirty:              2448 kB
Writeback:           512 kB
WritebackTmp:          0 kB
---
08:21:57
Dirty:              1644 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:21:58
Dirty:               640 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:21:59
Dirty:              1536 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:00
Dirty:               868 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:01
Dirty:              1728 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:02
Dirty:              1052 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:03
Dirty:              1268 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:04
Dirty:               720 kB
Writeback:           768 kB
WritebackTmp:          0 kB
---
08:22:05
Dirty:              1588 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:06
Dirty:               516 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:07
Dirty:              1328 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:08
Dirty:               400 kB
Writeback:          1024 kB
WritebackTmp:          0 kB
---
08:22:09
Dirty:              1264 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:10
Dirty:               764 kB
Writeback:           256 kB
WritebackTmp:          0 kB
---
08:22:11
Dirty:              1100 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:12
Dirty:               728 kB
Writeback:           256 kB
WritebackTmp:          0 kB
---
08:22:13
Dirty:              1488 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:14
Dirty:               360 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:15
Dirty:              1832 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:16
Dirty:               492 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:17
Dirty:              1988 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:18
Dirty:               792 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:19
Dirty:               816 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:20
Dirty:               520 kB
Writeback:           256 kB
WritebackTmp:          0 kB
---
08:22:21
Dirty:              1060 kB
Writeback:           256 kB
WritebackTmp:          0 kB
---
08:22:22
Dirty:               656 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:23
Dirty:              1632 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:24
Dirty:               344 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:25
Dirty:               972 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:26
Dirty:              3384 kB
Writeback:           768 kB
WritebackTmp:          0 kB
---
08:22:27
Dirty:               668 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:28
Dirty:              1024 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:29
Dirty:               872 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:30
Dirty:              2124 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:31
Dirty:              1124 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:32
Dirty:              1296 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:33
Dirty:               492 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:34
Dirty:               976 kB
Writeback:           256 kB
WritebackTmp:          0 kB
---
08:22:35
Dirty:              1448 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:36
Dirty:               252 kB
Writeback:           512 kB
WritebackTmp:          0 kB
---
08:22:37
Dirty:              1408 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:38
Dirty:               456 kB
Writeback:           256 kB
WritebackTmp:          0 kB
---
08:22:39
Dirty:               840 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:40
Dirty:               700 kB
Writeback:           512 kB
WritebackTmp:          0 kB
---
08:22:41
Dirty:              1332 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:42
Dirty:               556 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:43
Dirty:               844 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:44
Dirty:               892 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:45
Dirty:              1764 kB
Writeback:           512 kB
WritebackTmp:          0 kB
---
08:22:46
Dirty:               252 kB
Writeback:           360 kB
WritebackTmp:          0 kB
---
08:22:47
Dirty:               748 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:48
Dirty:               268 kB
Writeback:           256 kB
WritebackTmp:          0 kB
---
08:22:49
Dirty:              1116 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:50
Dirty:               964 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:51
Dirty:               452 kB
Writeback:           512 kB
WritebackTmp:          0 kB
---
08:22:52
Dirty:               708 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:53
Dirty:               608 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:54
Dirty:              1984 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:55
Dirty:               492 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:56
Dirty:              1192 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:22:57
Dirty:               972 kB
Writeback:           808 kB
WritebackTmp:          0 kB
---
08:22:58
Dirty:               876 kB
Writeback:           512 kB
WritebackTmp:          0 kB
---
08:22:59
Dirty:               732 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:00
Dirty:               612 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:01
Dirty:               960 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:02
Dirty:              1100 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:03
Dirty:              1248 kB
Writeback:           832 kB
WritebackTmp:          0 kB
---
08:23:04
Dirty:              1740 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:05
Dirty:              1304 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:06
Dirty:              1028 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:07
Dirty:              1348 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:08
Dirty:               460 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:09
Dirty:               364 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:10
Dirty:               924 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:11
Dirty:               780 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:12
Dirty:              2128 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:13
Dirty:               780 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:14
Dirty:               552 kB
Writeback:          1024 kB
WritebackTmp:          0 kB
---
08:23:15
Dirty:              1100 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:16
Dirty:               676 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:17
Dirty:              1108 kB
Writeback:          2128 kB
WritebackTmp:          0 kB
---
08:23:18
Dirty:               364 kB
Writeback:          1052 kB
WritebackTmp:          0 kB
---
08:23:19
Dirty:              1052 kB
Writeback:          2176 kB
WritebackTmp:          0 kB
---
08:23:20
Dirty:              2372 kB
Writeback:          1760 kB
WritebackTmp:          0 kB
---
08:23:21
Dirty:               992 kB
Writeback:          1816 kB
WritebackTmp:          0 kB
---
08:23:22
Dirty:              1432 kB
Writeback:          1736 kB
WritebackTmp:          0 kB
---
08:23:23
Dirty:              4096 kB
Writeback:          1080 kB
WritebackTmp:          0 kB
---
08:23:24
Dirty:              1556 kB
Writeback:          1400 kB
WritebackTmp:          0 kB
---
08:23:25
Dirty:              3556 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:26
Dirty:              2224 kB
Writeback:           856 kB
WritebackTmp:          0 kB
---
08:23:27
Dirty:              2308 kB
Writeback:          3552 kB
WritebackTmp:          0 kB
---
08:23:28
Dirty:              1520 kB
Writeback:          1672 kB
WritebackTmp:          0 kB
---
08:23:29
Dirty:              1336 kB
Writeback:          1016 kB
WritebackTmp:          0 kB
---
08:23:30
Dirty:              4116 kB
Writeback:           440 kB
WritebackTmp:          0 kB
---
08:23:31
Dirty:              1100 kB
Writeback:            28 kB
WritebackTmp:          0 kB
---
08:23:32
Dirty:              1200 kB
Writeback:          1684 kB
WritebackTmp:          0 kB
---
08:23:33
Dirty:              1428 kB
Writeback:          1332 kB
WritebackTmp:          0 kB
---
08:23:34
Dirty:              2456 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:35
Dirty:              3820 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:36
Dirty:              1952 kB
Writeback:           512 kB
WritebackTmp:          0 kB
---
08:23:37
Dirty:              4096 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:38
Dirty:              1504 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:39
Dirty:              1712 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:40
Dirty:              2780 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:41
Dirty:              2060 kB
Writeback:             0 kB
WritebackTmp:          0 kB
---
08:23:42
Dirty:               184 kB
Writeback:            24 kB
WritebackTmp:          0 kB
---

```

---

## Command 9: dstat

### Command
```bash
dstat -tcmdr --disk-util 1 130
```

### Output
```
----system---- ----total-usage---- ------memory-usage----- -dsk/total- --io/total- nvme nvme nvme nvme nvme nvme nvme nvme nvme nvme nvme nvme nvme nvme nvme nvme nvme
     time     |usr sys idl wai stl| used  free  buf   cach| read  writ| read  writ|util:util:util:util:util:util:util:util:util:util:util:util:util:util:util:util:util
04-01 08:21:39|                   |  22G 5824M   22M   34G|           |           |    :    :    :    :    :    :    :    :    :    :    :    :    :    :    :    :    
04-01 08:21:40|  0   0 100   0   0|  22G 5821M   22M   34G|   0   280k|   0  46.0 |0.20:   0:   0:0.20:   0:0.20:   0:   0:0.20:   0:   0:   0:   0:   0:   0:   0:   0
04-01 08:21:41|  0   0 100   0   0|  22G 5898M   22M   34G|   0   568k|   0  69.5 |   0:1.00:   0:   0:   0:   0:   0:   0:   0:0.10:   0:0.10:0.10:   0:0.20:0.10:0.30
04-01 08:21:42| 25  17  53   2   0|  22G 5721M   22M   34G| 900k   56M| 120  1811 |1.40:0.10:0.80:0.70:1.70:1.00:0.60:1.60:2.10:24.4:24.5:24.3:24.4:24.3:24.2:24.5:24.4
04-01 08:21:43| 26  17  52   2   0|  22G 5716M   22M   34G|1068k   60M| 140  1878 |1.50:   0:1.10:0.50:1.70:0.80:0.60:2.20:1.60:26.0:25.4:25.8:25.3:25.3:26.1:25.3:26.0
04-01 08:21:44| 26  16  52   2   0|  22G 5711M   22M   34G|1300k   65M| 164  2017 |2.80:0.10:1.10:1.20:3.10:1.50:0.70:1.80:2.70:25.5:25.7:25.4:26.1:25.9:25.5:26.7:25.7
04-01 08:21:45| 27  16  51   2   0|  22G 5696M   22M   34G|1640k   63M| 222  1952 |3.10:   0:0.90:0.80:3.00:1.90:0.70:2.20:3.40:26.5:24.7:25.7:25.7:24.5:25.9:25.9:26.3
04-01 08:21:46| 26  16  51   2   0|  22G 5694M   22M   34G| 684k   61M|94.0  1962 |1.90:0.10:0.60:1.30:1.90:0.80:0.20:1.30:1.40:25.5:26.3:25.9:25.0:26.5:25.6:25.1:25.8
04-01 08:21:47| 26  17  52   2   0|  22G 5690M   22M   34G| 844k   66M| 113  2002 |1.90:0.10:0.50:1.20:1.50:1.00:0.80:1.50:2.40:26.1:25.2:26.4:25.2:25.1:25.4:25.0:25.4
04-01 08:21:48| 26  17  51   2   0|  22G 5681M   22M   34G| 736k   60M|99.0  1959 |1.60:0.10:0.50:0.50:1.60:1.10:0.50:1.50:1.50:26.2:25.4:25.8:25.7:25.2:25.5:25.7:25.5
04-01 08:21:49| 26  16  52   1   0|  22G 5676M   22M   34G| 376k   64M|57.0  1984 |1.00:   0:0.30:0.90:1.30:1.00:0.30:1.00:1.10:25.2:26.0:25.3:25.4:26.0:25.2:25.5:24.8
04-01 08:21:50| 26  17  52   2   0|  22G 5675M   22M   34G| 932k   61M| 124  1927 |2.30:0.10:0.80:1.00:1.40:0.80:0.70:1.60:1.50:26.0:25.4:26.2:25.0:25.6:26.0:25.2:26.1
04-01 08:21:51| 26  16  51   1   0|  22G 5672M   22M   34G| 456k   64M|68.0  2047 |1.40:0.10:0.30:0.70:1.00:0.70:0.30:1.00:0.90:24.7:25.8:24.5:24.6:25.7:25.4:24.3:25.9
04-01 08:21:52| 27  17  50   2   0|  22G 5655M   23M   34G|  24M   61M| 418  1970 |1.20:19.8:0.20:0.50:1.20:0.60:0.50:1.00:1.70:26.6:25.8:25.9:26.4:25.9:25.7:25.5:25.4
04-01 08:21:53| 26  16  51   2   0|  22G 5643M   23M   34G| 456k   65M|60.0  2105 |1.20:0.10:0.50:0.60:1.00:0.70:0.50:0.60:1.30:25.0:25.7:25.0:25.7:26.0:25.5:25.7:25.5
04-01 08:21:54| 26  17  51   2   0|  22G 5648M   23M   34G| 364k   59M|53.0  1968 |0.70:   0:0.70:0.50:1.10:0.60:0.20:0.40:1.00:26.5:24.8:26.0:25.2:25.1:25.3:25.4:24.9
04-01 08:21:55| 27  17  51   2   0|  22G 5643M   23M   34G| 344k   59M|46.0  1981 |1.40:   0:0.60:0.80:1.30:0.90:0.50:1.20:1.10:24.9:26.1:25.2:24.9:26.2:26.1:25.0:26.5
04-01 08:21:56| 26  17  51   2   0|  22G 5635M   23M   34G| 284k   60M|40.0  1911 |0.60:   0:0.50:0.80:0.90:0.40:0.40:0.40:0.70:25.4:25.2:25.2:26.3:25.8:25.2:26.4:24.9
04-01 08:21:57| 26  16  51   2   0|  22G 5626M   23M   34G| 400k   63M|52.0  2067 |1.40:0.10:0.70:0.90:1.30:0.60:0.70:1.00:1.20:25.4:26.8:25.1:24.9:26.2:26.4:25.1:26.1
04-01 08:21:58| 27  16  51   2   0|  22G 5619M   23M   34G| 316k   60M|50.0  1968 |1.00:   0:0.40:0.60:1.00:0.60:0.50:0.60:1.30:26.2:24.1:26.4:25.6:24.7:24.9:25.3:25.3
04-01 08:21:59| 26  17  51   2   0|  22G 5609M   23M   34G| 336k   56M|46.0  1888 |0.80:0.20:0.10:0.10:0.50:0.20:   0:0.70:0.60:26.0:24.6:26.1:25.7:25.4:25.1:25.5:25.5
04-01 08:22:00| 26  17  51   1   0|  22G 5606M   23M   34G| 296k   59M|44.0  1915 |1.20:0.10:0.60:0.70:1.30:0.70:0.40:0.70:1.10:25.1:25.7:25.2:25.3:25.7:25.8:25.1:25.8
04-01 08:22:01| 26  17  51   2   0|  22G 5608M   23M   34G| 212k   55M|29.0  1837 |0.30:   0:0.10:   0:0.60:   0:0.10:0.40:0.20:25.6:25.7:25.3:24.7:25.5:25.3:24.9:25.2
04-01 08:22:02| 26  17  51   2   0|  22G 5606M   23M   34G| 292k   59M|44.0  1951 |1.40:0.10:1.00:0.70:1.00:0.60:0.70:1.10:1.00:24.8:25.0:24.9:25.6:25.5:26.0:25.2:26.0
04-01 08:22:03| 27  17  51   1   0|  22G 5602M   23M   34G| 152k   55M|20.0  1878 |0.60:   0:0.40:0.20:0.70:0.30:0.20:0.30:0.40:24.7:25.6:25.3:25.6:25.6:25.7:24.8:25.6
04-01 08:22:04| 27  17  51   2   0|  22G 5604M   23M   34G| 216k   57M|33.0  1936 |1.00:0.10:0.50:0.60:1.00:0.30:0.60:0.80:0.60:24.3:26.0:24.3:26.0:25.9:24.9:26.2:25.0
04-01 08:22:05| 26  17  51   1   0|  22G 5600M   23M   34G| 172k   55M|26.0  1874 |0.60:   0:0.30:0.20:0.70:0.20:0.20:0.20:0.50:25.9:25.5:25.3:25.8:25.2:24.9:25.2:24.7
04-01 08:22:06| 26  17  51   2   0|  22G 5602M   23M   34G| 140k   58M|22.0  1968 |0.50:0.20:0.20:0.20:0.50:0.20:0.40:0.20:0.70:25.4:25.3:25.1:25.6:25.3:25.8:25.8:25.8
04-01 08:22:07| 26  17  51   2   0|  22G 5597M   23M   34G| 104k   56M|20.0  1888 |0.40:   0:0.20:0.30:0.80:0.20:0.20:0.40:0.70:25.3:25.9:25.6:25.1:26.1:25.9:24.8:25.9
04-01 08:22:08| 26  17  51   2   0|  22G 5588M   23M   34G| 176k   59M|25.0  2023 |1.00:0.10:0.70:0.70:0.90:0.60:0.60:0.80:1.00:25.2:25.3:25.4:26.1:25.7:25.1:25.8:25.1
04-01 08:22:09| 26  17  51   1   0|  22G 5585M   23M   34G|  96k   55M|15.0  1905 |0.80:   0:0.70:0.70:0.80:0.60:0.70:0.80:0.90:25.8:25.5:25.6:24.3:25.4:25.4:24.4:26.2
04-01 08:22:10| 26  17  51   2   0|  22G 5584M   23M   34G| 140k   58M|20.0  2025 |0.70:0.10:0.80:0.60:0.80:0.70:0.50:0.70:0.90:25.7:25.2:26.2:25.7:25.3:24.7:25.8:24.6
04-01 08:22:11| 27  17  51   1   0|  22G 5580M   23M   34G| 120k   58M|19.0  1959 |0.50:   0:0.40:0.30:0.50:0.30:0.30:0.70:0.60:25.9:25.4:25.6:24.6:25.5:25.6:24.4:26.0
04-01 08:22:12| 27  17  51   2   0|  22G 5574M   23M   34G|  32k   60M|5.00  2008 |0.60:0.10:0.60:0.50:0.60:0.40:0.50:0.60:0.50:25.4:25.6:25.3:24.5:25.5:26.0:24.8:25.7
04-01 08:22:13| 26  17  51   2   0|  22G 5573M   23M   34G|  28k   56M|5.00  1934 |0.80:   0:0.50:0.80:0.60:0.60:0.60:0.90:0.60:24.9:24.7:24.7:25.4:24.9:25.0:25.1:25.5
04-01 08:22:14| 26  18  51   2   0|  22G 5574M   23M   34G|  92k   60M|15.0  2045 |0.80:0.10:0.70:0.60:1.10:0.50:0.60:0.70:0.80:24.8:25.7:24.7:25.6:25.1:25.8:25.9:25.9
04-01 08:22:15| 27  17  51   2   0|  22G 5567M   23M   34G|  68k   55M|11.0  1905 |0.50:0.10:0.20:0.20:0.50:0.30:0.20:0.40:0.40:26.5:25.8:26.2:24.4:25.8:25.3:24.0:25.7
04-01 08:22:16| 27  17  51   1   0|  22G 5561M   23M   34G|  80k   60M|12.0  2000 |0.70:   0:0.50:0.60:0.70:0.50:0.50:0.60:0.50:24.9:25.5:24.5:25.6:25.5:25.9:25.6:25.6
04-01 08:22:17| 27  17  51   2   0|  22G 5574M   23M   34G|  96k   54M|14.0  1935 |0.40:0.10:0.20:0.20:0.30:0.20:0.20:0.30:0.30:25.5:25.0:26.0:25.2:25.2:24.9:25.5:25.2
04-01 08:22:18| 27  17  51   1   0|  22G 5574M   23M   34G| 100k   62M|13.0  2029 |0.80:0.10:0.40:0.50:0.60:0.40:0.40:0.50:0.50:25.0:24.7:25.1:23.7:25.2:25.6:23.9:25.3
04-01 08:22:19| 26  17  50   2   0|  22G 5582M   23M   34G| 120k   55M|19.0  1961 |0.90:0.20:0.50:0.50:0.70:0.60:0.40:0.50:0.80:25.6:25.2:25.9:25.3:25.0:25.3:25.3:25.4
04-01 08:22:20| 26  17  51   2   0|  22G 5571M   23M   34G|  32k   58M|6.00  1971 |1.00:   0:1.00:0.90:1.00:1.00:0.70:0.90:0.90:24.3:26.1:24.3:25.0:25.5:25.9:25.3:25.3
04-01 08:22:21| 27  17  51   2   0|  22G 5578M   23M   34G|  32k   57M|6.00  1987 |0.40:0.20:0.30:0.30:0.40:0.30:0.50:0.40:0.40:25.2:25.9:25.2:25.4:26.2:23.8:25.3:24.3
04-01 08:22:22| 27  17  51   1   0|  22G 5574M   23M   34G|  60k   56M|10.0  1951 |0.40:0.20:0.40:0.50:0.60:0.40:0.50:0.60:0.60:25.5:24.1:25.3:24.8:24.1:25.7:24.9:26.0
04-01 08:22:23| 26  17  50   2   0|  22G 5574M   23M   34G| 100k   53M|16.0  1863 |0.20:   0:0.30:0.10:0.60:   0:   0:0.30:0.10:24.6:25.0:25.0:25.0:25.0:25.0:25.2:25.3
04-01 08:22:24| 27  17  50   1   0|  22G 5566M   23M   34G|  64k   57M|9.00  1998 |0.40:0.10:0.30:0.30:0.30:0.30:0.30:0.30:0.50:26.0:24.8:25.4:25.7:25.0:23.8:25.7:24.0
04-01 08:22:25| 26  17  50   2   0|  22G 5573M   23M   34G|  68k   55M|12.0  1938 |0.30:   0:0.20:0.40:0.30:0.40:0.10:0.20:0.40:24.8:25.6:24.7:24.5:25.5:25.5:24.4:24.9
04-01 08:22:26| 27  18  50   2   0|  22G 5565M   23M   34G|8192B   53M|2.00  1935 |0.10:0.20:0.10:0.10:0.20:0.20:0.70:0.10:0.20:24.9:25.0:25.2:25.9:25.3:25.0:25.9:24.9
04-01 08:22:27| 27  17  50   1   0|  22G 5563M   23M   34G|  12k   62M|3.00  2045 |0.90:   0:0.80:0.80:0.80:0.60:0.80:0.90:0.80:25.0:25.3:24.9:25.1:25.2:25.8:24.9:25.7
04-01 08:22:28| 26  17  50   1   0|  22G 5556M   23M   34G|8192B   54M|2.00  1967 |0.30:0.10:0.20:0.20:0.20:0.20:0.10:0.20:0.20:25.8:25.1:25.6:26.3:24.9:24.6:26.4:24.4
04-01 08:22:29| 27  18  50   1   0|  22G 5548M   23M   34G|  36k   58M|6.00  2015 |0.80:   0:0.70:0.70:1.00:0.60:0.50:0.80:0.60:24.3:26.4:24.2:24.9:26.0:25.5:25.1:25.5
04-01 08:22:30| 26  17  50   2   0|  22G 5551M   23M   34G|  20k   54M|2.00  1947 |0.40:0.10:0.30:0.40:0.40:0.30:0.40:0.40:0.30:26.0:25.8:26.2:25.5:25.7:25.5:25.1:25.6
04-01 08:22:31| 27  17  50   1   0|  22G 5560M   23M   34G|4096B   60M|1.00  2027 |0.70:   0:0.80:0.70:0.80:1.00:0.90:0.80:1.10:25.3:24.4:25.0:25.6:24.7:24.8:25.7:24.7
04-01 08:22:32| 27  17  50   2   0|  22G 5554M   23M   34G|  20k   54M|3.00  1958 |0.40:0.10:0.40:0.40:0.40:0.30:0.40:0.40:0.30:24.9:25.2:25.2:26.1:25.3:24.8:25.8:25.1
04-01 08:22:33| 27  18  50   2   0|  22G 5557M   23M   34G|  20k   56M|4.00  1962 |0.90:0.20:0.90:0.90:1.00:0.90:0.90:0.90:0.90:25.7:25.7:25.5:24.8:25.8:25.1:24.9:25.1
04-01 08:22:34| 27  17  50   2   0|  22G 5553M   23M   34G|  28k   55M|4.00  1984 |0.60:0.10:0.60:0.60:0.60:0.70:0.50:0.50:0.50:24.8:25.1:24.8:24.9:25.0:25.8:24.5:26.2
04-01 08:22:35| 27  17  50   1   0|  22G 5548M   23M   34G|   0    54M|   0  1923 |0.60:   0:0.60:0.60:0.60:0.60:0.50:0.50:0.60:24.9:25.7:24.7:25.3:25.5:24.9:25.2:25.1
04-01 08:22:36| 27  17  50   1   0|  22G 5540M   23M   34G|  20k   56M|3.00  1993 |0.60:0.10:0.60:0.60:0.60:0.60:0.40:0.50:0.60:25.0:25.3:25.2:25.6:25.3:25.3:25.1:25.6
04-01 08:22:37| 27  17  50   2   0|  22G 5538M   23M   34G|  28k   53M|3.00  1926 |0.50:   0:0.60:0.60:0.70:0.60:0.70:0.80:0.80:26.3:25.1:25.8:25.1:25.3:25.3:24.6:25.3
04-01 08:22:38| 27  17  50   2   0|  22G 5532M   23M   34G|4096B   58M|1.00  2048 |0.60:0.10:0.60:0.60:0.50:0.60:0.60:0.70:0.60:25.2:25.3:25.0:25.3:25.7:25.5:25.1:25.5
04-01 08:22:39| 27  17  50   1   0|  22G 5529M   23M   34G|  48k   54M|8.00  1949 |0.50:   0:0.40:0.40:0.50:0.40:0.40:0.50:0.60:25.4:25.5:25.2:25.3:24.7:25.5:25.6:25.6
04-01 08:22:40| 27  17  50   1   0|  22G 5525M   23M   34G|  28k   54M|4.00  2013 |0.60:0.10:0.50:0.50:0.70:0.50:0.40:0.40:0.50:25.7:24.3:25.6:25.5:24.7:25.6:25.7:25.2
04-01 08:22:41| 27  17  50   2   0|  22G 5521M   23M   34G|8192B   52M|2.00  1905 |0.20:   0:0.20:0.30:0.20:0.20:0.20:0.20:0.30:26.5:24.7:26.3:23.9:24.4:25.0:24.3:24.9
04-01 08:22:42| 26  17  50   1   0|  22G 5517M   23M   34G|  40k   56M|5.00  2046 |0.60:0.10:1.10:0.60:1.20:1.00:0.80:0.80:1.10:25.0:24.8:25.1:25.4:24.9:24.9:25.5:25.5
04-01 08:22:43| 27  17  50   2   0|  22G 5520M   23M   34G|  32k   52M|5.00  1909 |0.20:   0:0.30:0.30:0.40:0.30:0.30:0.40:0.30:25.4:25.1:25.3:25.9:25.6:25.3:25.8:25.5
04-01 08:22:44| 27  17  50   2   0|  22G 5516M   23M   34G|  24k   54M|4.00  1967 |0.60:0.10:0.60:0.60:0.60:0.60:0.50:0.60:0.60:25.5:25.4:25.1:26.0:25.4:24.5:25.8:24.6
04-01 08:22:45| 28  18  49   2   0|  22G 5510M   23M   34G|  40k   54M|6.00  1906 |0.40:   0:0.30:0.40:0.60:0.30:0.30:0.40:0.30:26.2:24.2:26.0:23.9:24.2:26.6:24.5:26.3
04-01 08:22:46| 27  17  50   1   0|  22G 5507M   23M   34G|8192B   57M|2.00  2075 |0.50:0.10:0.70:0.50:0.80:0.70:0.70:0.60:0.70:24.4:24.8:24.1:25.7:25.3:25.0:25.6:25.0
04-01 08:22:47| 27  17  50   1   0|  22G 5506M   23M   34G|  16k   51M|3.00  1892 |0.20:   0:0.20:0.20:0.30:0.20:0.10:0.30:0.20:25.8:24.8:26.2:25.6:25.1:24.2:25.8:24.2
04-01 08:22:48| 27  18  50   1   0|  22G 5500M   23M   34G|4095B   51M|1.00  1889 |0.20:   0:0.10:0.10:0.10:0.30:   0:   0:0.20:24.8:25.4:24.5:24.1:25.9:25.5:24.4:25.6
04-01 08:22:49| 27  17  50   2   0|  22G 5500M   23M   34G|  32k   54M|4.00  2007 |0.50:0.10:0.50:0.50:0.60:0.60:0.40:0.60:0.60:25.2:25.4:24.9:25.2:25.3:25.2:25.1:25.1
04-01 08:22:50| 26  18  50   1   0|  22G 5500M   23M   34G|  44k   53M|7.00  1928 |0.50:   0:0.60:0.40:0.60:0.50:0.40:0.50:0.60:25.8:25.1:25.6:24.0:24.8:26.1:23.5:25.9
04-01 08:22:51| 27  18  50   2   0|  22G 5497M   23M   34G|4096B   55M|1.00  2021 |0.60:0.10:0.70:0.60:0.60:0.60:0.60:0.70:0.60:24.0:25.9:24.2:26.7:26.0:24.6:26.8:24.4
04-01 08:22:52| 27  17  50   1   0|  22G 5499M   23M   34G|   0    52M|   0  1918 |0.40:0.20:0.40:0.40:0.40:0.30:0.40:0.40:0.30:25.8:23.9:25.8:25.4:24.0:25.4:25.1:25.0
04-01 08:22:53| 27  18  50   2   0|  22G 5509M   23M   34G|   0    55M|   0  2025 |0.70:0.10:0.70:0.60:0.50:0.60:0.70:0.60:0.60:24.3:26.2:24.2:24.9:26.3:25.4:24.0:25.4
04-01 08:22:54| 28  17  50   1   0|  22G 5511M   23M   34G|  44k   54M|6.00  1990 |0.60:   0:0.60:0.70:0.60:0.50:0.50:0.60:0.70:26.2:25.2:26.6:25.1:24.8:24.8:25.2:24.5
04-01 08:22:55| 26  17  50   2   0|  22G 5517M   23M   34G| 272k   55M|17.0  1998 |0.70:0.50:0.60:0.60:0.60:0.60:0.60:0.60:0.60:24.4:25.9:24.3:24.8:25.9:24.8:24.8:24.6
04-01 08:22:56| 27  17  50   1   0|  22G 5520M   23M   34G|8192B   52M|1.00  1930 |0.20:   0:0.10:0.10:0.30:0.30:0.20:0.20:0.20:25.3:24.8:25.4:24.9:24.6:26.0:24.5:25.8
04-01 08:22:57| 26  17  50   1   0|  22G 5515M   23M   34G|   0    58M|   0  2079 |0.40:0.10:0.40:0.50:0.40:0.40:0.50:0.50:0.40:25.9:24.2:25.6:25.5:24.5:25.6:26.1:25.7
04-01 08:22:58| 28  17  50   1   0|  22G 5509M   23M   34G|  16k   52M|3.00  1932 |0.70:   0:0.70:0.70:0.80:0.60:0.70:0.60:0.60:24.2:25.7:24.1:25.1:26.0:24.6:24.9:25.4
04-01 08:22:59| 27  17  50   1   0|  22G 5501M   23M   34G|  20k   55M|4.00  2070 |0.90:0.30:0.70:0.80:0.80:0.80:0.70:0.90:0.70:24.9:25.5:24.6:24.7:25.5:26.8:24.2:26.6
04-01 08:23:00| 27  17  50   1   0|  22G 5509M   23M   34G|   0    51M|   0  1944 |0.50:0.10:0.50:0.60:0.50:0.50:0.50:0.50:0.50:24.3:24.3:24.8:24.8:24.7:25.2:25.1:25.5
04-01 08:23:01| 27  18  50   2   0|  22G 5513M   23M   34G|4096B   53M|1.00  1959 |0.40:   0:0.50:0.40:0.50:0.90:0.50:0.50:0.90:25.6:24.4:25.6:25.7:24.3:24.3:25.6:24.5
04-01 08:23:02| 27  18  50   2   0|  22G 5509M   23M   34G|   0    53M|   0  2001 |0.60:0.20:0.60:0.50:0.70:0.70:0.50:0.50:0.70:25.0:24.7:25.1:25.4:24.7:25.2:25.3:24.8
04-01 08:23:03| 28  17  50   1   0|  22G 5499M   23M   34G|4096B   53M|1.00  1960 |0.40:   0:0.40:0.50:0.50:0.40:0.60:0.50:0.40:25.5:25.1:25.2:25.5:25.2:24.8:25.6:25.0
04-01 08:23:04| 28  17  50   1   0|  22G 5502M   23M   34G|  16k   52M|2.00  1999 |0.80:0.10:0.70:0.80:0.70:0.90:0.70:0.70:0.90:25.3:24.9:24.9:25.3:24.7:25.2:25.1:25.3
04-01 08:23:05| 27  18  49   1   0|  22G 5496M   23M   34G|   0    53M|   0  1963 |0.40:0.10:0.60:0.40:0.40:0.50:0.50:0.50:0.40:24.8:25.1:25.0:25.7:25.0:24.8:25.9:24.3
04-01 08:23:06| 27  17  50   1   0|  22G 5492M   23M   34G|8192B   54M|1.00  2017 |0.60:0.10:0.80:0.60:1.00:0.70:0.70:0.70:0.70:25.6:24.3:25.7:25.5:24.4:25.6:25.4:24.7
04-01 08:23:07| 27  17  50   1   0|  22G 5497M   23M   34G|  40k   53M|5.00  1909 |0.70:   0:0.70:0.70:0.70:0.70:0.70:0.80:0.70:24.7:25.1:25.3:24.2:25.4:25.5:24.5:25.6
04-01 08:23:08| 27  18  49   2   0|  22G 5495M   23M   34G|  12k   54M|2.00  2026 |0.80:0.10:0.70:0.90:0.90:0.70:0.90:1.00:0.70:24.9:25.7:25.3:24.9:25.4:25.8:24.9:25.2
04-01 08:23:09| 27  17  50   1   0|  22G 5492M   23M   34G|  28k   50M|4.00  1898 |0.30:   0:0.20:0.20:0.30:0.20:0.20:0.20:0.20:25.0:25.1:24.9:25.9:25.2:25.2:25.5:25.0
04-01 08:23:10| 28  17  49   2   0|  22G 5490M   23M   34G|   0    56M|   0  2083 |0.80:0.10:0.90:0.90:0.80:1.00:0.90:1.10:1.10:25.2:24.5:25.0:25.1:24.8:25.3:24.7:25.1
04-01 08:23:11| 27  18  50   2   0|  22G 5487M   23M   34G|   0    51M|   0  1924 |0.30:0.10:0.20:0.30:0.20:0.40:0.20:0.20:0.40:25.0:25.2:25.0:25.4:25.0:25.5:24.9:25.2
04-01 08:23:12| 27  18  50   2   0|  22G 5497M   23M   34G|4096B   53M|1.00  2012 |0.60:0.10:0.50:0.60:0.50:0.60:0.60:0.70:0.60:25.3:24.7:25.1:25.2:25.2:24.9:24.9:24.8
04-01 08:23:13| 27  17  50   2   0|  22G 5485M   23M   34G|8192B   55M|1.00  1999 |0.60:   0:0.70:0.60:0.30:0.60:0.70:0.60:0.60:25.5:25.1:25.1:24.8:25.1:25.4:24.4:25.1
04-01 08:23:14| 27  18  49   1   0|  22G 5479M   23M   34G|   0    53M|   0  2013 |0.80:0.20:0.60:0.80:0.80:0.90:0.70:0.80:0.90:25.1:24.4:25.0:25.7:24.4:25.2:25.6:24.9
04-01 08:23:15| 27  18  49   1   0|  22G 5484M   23M   34G|4095B   52M|1.00  1951 |0.40:0.10:0.40:0.40:0.50:0.40:0.40:0.40:0.40:25.0:25.0:24.8:25.0:25.3:25.0:24.4:25.2
04-01 08:23:16| 35  16  44   1   0|  22G 5487M   23M   34G|   0    48M|   0  1893 |0.60:   0:0.40:0.60:0.40:0.40:0.80:0.90:0.50:22.5:22.9:22.4:22.5:22.6:28.8:22.5:28.6
04-01 08:23:17| 27  17  49   1   0|  22G 5482M   23M   34G|  12k   50M|2.00  1941 |0.20:0.20:0.20:0.20:0.30:0.20:0.20:0.30:0.20:24.7:23.3:25.3:25.1:23.4:26.8:25.0:26.9
04-01 08:23:18| 35  16  43   1   0|  22G 5512M   23M   34G|  12k  290M|2.00  33.1k|16.1:   0:16.3:16.1:16.5:16.1:16.7:16.2:16.1:25.1:23.5:24.8:25.4:23.5:23.1:25.6:23.1
04-01 08:23:19| 27  18  49   1   0|  22G 5515M   23M   34G|  12k  341M|3.00  39.1k|20.9:0.10:19.1:20.8:18.8:19.4:20.3:19.8:20.3:25.6:24.9:26.0:25.4:24.7:25.2:25.3:25.4
04-01 08:23:20| 27  17  48   2   0|  22G 5517M   23M   34G|8192B  237M|1.00  25.6k|43.3:0.10:16.0:42.6:15.8:83.2: 100: 100:83.4:25.1:24.2:24.9:24.4:24.6:25.3:24.3:25.3
04-01 08:23:21| 27  17  49   2   0|  22G 5513M   23M   34G|   0   242M|   0  26.0k|89.7:0.10:16.0:89.1:16.4: 100:91.8:91.6: 100:23.9:26.2:24.2:25.3:26.4:23.9:25.2:24.0
04-01 08:23:22| 27  18  48   2   0|  22G 5520M   23M   34G|   0   235M|   0  25.6k|93.5:0.10:15.3:93.3:15.8: 100:26.6:26.7: 100:25.7:24.2:25.6:24.4:24.1:25.6:24.3:25.8
04-01 08:23:23| 28  18  48   2   0|  22G 5510M   23M   34G|  28k  233M|3.00  25.3k|28.3:0.30:26.1:27.8:25.9:82.0:25.9:25.9:81.4:24.7:26.1:24.9:23.7:25.8:25.8:24.1:26.2
04-01 08:23:24| 27  18  48   2   0|  22G 5507M   23M   34G|  28k  250M|4.00  26.7k|34.6:0.10:33.4:33.4:33.7:67.4:33.8:34.1:67.2:25.4:24.9:25.0:25.4:25.3:24.6:25.4:24.1
04-01 08:23:25| 27  18  48   2   0|  22G 5504M   23M   34G|8189B  243M|1.00  26.2k|70.2:0.10:23.4:68.6:24.2:89.4:32.2:34.1:89.6:25.0:24.8:24.6:25.6:24.8:24.5:25.6:25.0
04-01 08:23:26| 28  18  48   2   0|  22G 5495M   23M   34G|8195B  240M|1.00  25.9k| 100:0.10:17.5: 100:17.5:99.3:17.3:17.6:99.5:25.5:24.2:25.4:23.9:24.4:25.1:23.9:25.1
04-01 08:23:27| 28  17  48   2   0|  22G 5490M   23M   34G|  12k  241M|2.00  26.0k|61.6:   0:26.5:60.2:26.6:82.6:30.8:32.5:82.4:24.2:25.2:24.0:26.1:25.2:25.5:25.8:25.4
04-01 08:23:28| 28  18  48   2   0|  22G 5490M   23M   34G|   0   242M|   0  26.1k|93.1:0.10:16.1:92.1:16.4: 100:42.2:45.2: 100:25.6:24.3:25.5:24.9:24.8:25.0:24.6:25.2
04-01 08:23:29| 26  18  48   2   0|  22G 5483M   23M   34G|   0   241M|   0  25.9k|72.6:   0:16.5:69.8:16.5:99.3:95.7:96.5:99.5:25.3:25.6:25.0:24.1:25.4:25.0:24.3:25.1
04-01 08:23:30| 27  18  48   2   0|  22G 5490M   23M   34G|   0   234M|   0  25.6k|16.9:0.10:15.8:16.8:15.4:95.9:96.3:97.4:96.1:25.0:24.9:25.2:25.9:25.0:24.5:25.7:24.7
04-01 08:23:31| 27  18  48   2   0|  22G 5491M   23M   34G|   0   248M|   0  26.4k|19.1:   0:16.3:18.5:16.2:93.7:99.6:99.8:94.2:24.9:24.2:24.9:25.2:23.8:25.3:25.0:25.7
04-01 08:23:32| 27  18  48   2   0|  22G 5483M   23M   34G|   0   237M|   0  25.9k|99.2:0.10:16.1:99.1:15.9:86.7: 100: 100:87.4:24.2:25.9:23.8:25.0:25.7:25.3:24.7:25.0
04-01 08:23:33| 28  18  48   2   0|  22G 5486M   23M   34G|   0   243M|   0  25.9k|85.5:   0:16.3:83.0:16.5:30.2: 100: 100:30.7:25.7:24.5:26.4:25.1:24.7:25.0:25.2:24.6
04-01 08:23:34| 28  18  48   2   0|  22G 5477M   23M   34G|   0   187M|   0  19.3k|20.8:0.10:11.5:12.3:11.6:12.1:75.1:75.2:12.7:24.3:25.9:24.3:24.7:25.7:25.5:24.2:25.0
04-01 08:23:35| 27  18  49   2   0|  22G 5476M   23M   34G|8192B   50M|1.00  2021 |0.30:   0:0.30:0.30:0.30:0.40:0.30:0.40:0.40:25.5:24.3:25.2:25.4:24.0:24.5:25.5:24.6
04-01 08:23:36| 27  17  49   1   0|  22G 5460M   23M   34G|   0    57M|   0  2188 |0.40:0.10:0.60:0.60:0.60:0.60:0.30:0.30:0.60:24.6:25.6:24.7:24.3:25.8:26.0:24.4:26.1
04-01 08:23:37| 27  17  50   2   0|  22G 5451M   23M   34G|  12k   50M|2.00  2021 |0.10:   0:0.30:0.30:0.30:0.30:0.30:0.20:0.30:25.7:24.1:25.4:25.4:24.0:24.7:25.1:24.3
04-01 08:23:38| 27  18  50   1   0|  22G 5449M   23M   34G|   0    59M|   0  2256 |0.20:0.20:0.60:0.70:0.80:0.60:0.60:0.60:0.70:24.9:25.9:24.6:24.4:25.5:24.5:24.7:24.7
04-01 08:23:39| 28  18  49   1   0|  22G 5444M   23M   34G|   0    52M|   0  2055 |0.20:   0:0.40:0.40:0.40:0.30:0.40:0.40:0.30:25.7:23.9:25.2:24.5:24.0:25.2:24.8:25.2
04-01 08:23:40| 27  17  49   2   0|  22G 5435M   23M   34G|   0    53M|   0  2161 |0.10:0.10:0.60:0.40:0.60:0.60:0.40:0.40:0.50:24.2:26.1:24.1:25.2:25.6:24.0:25.4:24.5
04-01 08:23:41| 27  17  49   1   0|  22G 5439M   23M   34G|   0    54M|   0  2105 |0.20:   0:0.50:0.50:0.50:0.50:0.50:0.50:0.50:24.8:24.5:24.9:24.2:24.8:26.1:24.1:26.1
04-01 08:23:42|  0   1  99   0   0|  22G 5672M   23M   34G|   0  3588k|   0   174 |0.10:0.10:0.30:0.30:0.30:0.20:0.40:0.40:0.20:0.50:0.10:0.50:0.10:0.10:0.10:0.10:0.20
04-01 08:23:43|  0   0 100   0   0|  22G 5669M   23M   34G|   0   164k|   0  51.0 |   0:   0:0.20:0.10:   0:0.10:0.30:0.10:0.10:   0:   0:   0:   0:   0:   0:   0:   0

```

---

## Command 10: mpstat

### Command
```bash
mpstat -P ALL 1 130
```

### Output
```
Linux 6.14.0-1018-aws (ip-10-0-1-171) 	01/04/26 	_aarch64_	(32 CPU)

08:21:39     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:40     all    0.16    0.00    0.12    0.00    0.00    0.00    0.00    0.00    0.00   99.72
08:21:40       0    1.00    0.00    1.00    0.00    0.00    0.00    0.00    0.00    0.00   98.00
08:21:40       1    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40       2    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40       3    0.00    0.00    0.99    0.00    0.00    0.00    0.00    0.00    0.00   99.01
08:21:40       4    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40       5    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40       6    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40       7    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40       8    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40       9    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      10    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      11    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      12    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      13    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      14    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      15    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      16    0.00    0.00    0.99    0.00    0.00    0.00    0.00    0.00    0.00   99.01
08:21:40      17    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      18    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      19    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      20    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      21    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      22    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      23    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      24    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      25    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      26    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      27    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      28    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      29    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      30    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:40      31    3.96    0.00    0.99    0.00    0.00    0.00    0.00    0.00    0.00   95.05

08:21:40     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:41     all    0.06    0.00    0.06    0.00    0.00    0.00    0.00    0.00    0.00   99.87
08:21:41       0    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41       1    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41       2    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41       3    1.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00   99.00
08:21:41       4    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41       5    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41       6    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41       7    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41       8    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41       9    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      10    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      11    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      12    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      13    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      14    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      15    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      16    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      17    1.00    0.00    1.00    0.00    0.00    0.00    0.00    0.00    0.00   98.00
08:21:41      18    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      19    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      20    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      21    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      22    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      23    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      24    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      25    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      26    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      27    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      28    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      29    0.00    0.00    0.99    0.00    0.00    0.00    0.00    0.00    0.00   99.01
08:21:41      30    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:21:41      31    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00

08:21:41     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:42     all   24.68    0.00   16.51    1.55    0.00    0.00    0.00    0.00    0.00   57.25
08:21:42       0   26.04    0.00   14.58    1.04    0.00    0.00    0.00    0.00    0.00   58.33
08:21:42       1   25.00    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   58.33
08:21:42       2   24.74    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   55.67
08:21:42       3   23.71    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   56.70
08:21:42       4   24.74    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   56.70
08:21:42       5   25.26    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   56.84
08:21:42       6   24.74    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   57.73
08:21:42       7   26.04    0.00   14.58    1.04    0.00    0.00    0.00    0.00    0.00   58.33
08:21:42       8   23.96    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   57.29
08:21:42       9   25.25    0.00   17.17    1.01    0.00    0.00    0.00    0.00    0.00   56.57
08:21:42      10   23.71    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   55.67
08:21:42      11   26.32    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   55.79
08:21:42      12   25.77    0.00   15.46    2.06    0.00    0.00    0.00    0.00    0.00   56.70
08:21:42      13   25.51    0.00   16.33    2.04    0.00    0.00    0.00    0.00    0.00   56.12
08:21:42      14   24.74    0.00   16.49    3.09    0.00    0.00    0.00    0.00    0.00   55.67
08:21:42      15   24.74    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   56.70
08:21:42      16   24.49    0.00   16.33    2.04    0.00    0.00    0.00    0.00    0.00   57.14
08:21:42      17   24.49    0.00   17.35    1.02    0.00    0.00    0.00    0.00    0.00   57.14
08:21:42      18   23.71    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   56.70
08:21:42      19   22.92    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   58.33
08:21:42      20   25.51    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   55.10
08:21:42      21   27.08    0.00   13.54    1.04    0.00    0.00    0.00    0.00    0.00   58.33
08:21:42      22   24.21    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   58.95
08:21:42      23   24.49    0.00   17.35    1.02    0.00    0.00    0.00    0.00    0.00   57.14
08:21:42      24   24.74    0.00   15.46    2.06    0.00    0.00    0.00    0.00    0.00   57.73
08:21:42      25   23.96    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   57.29
08:21:42      26   23.47    0.00   17.35    1.02    0.00    0.00    0.00    0.00    0.00   58.16
08:21:42      27   23.96    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   58.33
08:21:42      28   23.71    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   57.73
08:21:42      29   25.26    0.00   14.74    1.05    0.00    0.00    0.00    0.00    0.00   58.95
08:21:42      30   23.96    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   58.33
08:21:42      31   23.71    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   57.73

08:21:42     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:43     all   26.83    0.00   17.57    1.63    0.00    0.00    0.00    0.00    0.00   53.96
08:21:43       0   26.60    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:21:43       1   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:43       2   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:21:43       3   25.26    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:43       4   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:43       5   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:43       6   28.12    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:43       7   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:43       8   29.17    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:43       9   25.77    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:43      10   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:43      11   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:43      12   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:43      13   27.08    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   55.21
08:21:43      14   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:43      15   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:43      16   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:43      17   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:43      18   25.00    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   56.25
08:21:43      19   26.04    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   55.21
08:21:43      20   26.80    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:43      21   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:43      22   26.04    0.00   17.71    3.12    0.00    0.00    0.00    0.00    0.00   53.12
08:21:43      23   26.04    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   55.21
08:21:43      24   25.26    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:43      25   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:43      26   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:43      27   28.12    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:43      28   26.04    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:43      29   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:43      30   26.04    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   55.21
08:21:43      31   26.88    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   54.84

08:21:43     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:44     all   27.07    0.00   17.28    1.63    0.00    0.00    0.00    0.00    0.00   54.02
08:21:44       0   27.66    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:21:44       1   29.47    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:21:44       2   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:44       3   28.57    0.00   16.33    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:21:44       4   26.88    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   55.91
08:21:44       5   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:44       6   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:44       7   26.60    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:21:44       8   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:44       9   26.04    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:44      10   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:44      11   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:44      12   26.04    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   55.21
08:21:44      13   25.77    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:44      14   27.66    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:44      15   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:44      16   26.53    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:21:44      17   27.55    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:21:44      18   26.80    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:21:44      19   27.08    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:44      20   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:44      21   26.32    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   55.79
08:21:44      22   28.87    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:21:44      23   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:44      24   27.66    0.00   14.89    1.06    0.00    0.00    0.00    0.00    0.00   56.38
08:21:44      25   25.81    0.00   17.20    2.15    0.00    0.00    0.00    0.00    0.00   54.84
08:21:44      26   25.77    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:44      27   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:44      28   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:44      29   27.08    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   55.21
08:21:44      30   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:44      31   25.77    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   54.64

08:21:44     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:45     all   27.95    0.00   17.17    1.63    0.00    0.00    0.00    0.00    0.00   53.25
08:21:45       0   32.29    0.00   14.58    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:21:45       1   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:21:45       2   25.00    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:45       3   25.53    0.00   20.21    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:21:45       4   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:21:45       5   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:45       6   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:45       7   31.63    0.00   16.33    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:21:45       8   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:21:45       9   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:45      10   25.77    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:45      11   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:45      12   28.42    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:45      13   29.17    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:45      14   32.63    0.00   14.74    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:21:45      15   27.08    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:45      16   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:45      17   30.85    0.00   13.83    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:45      18   25.53    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:45      19   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:45      20   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:45      21   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:21:45      22   29.47    0.00   14.74    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:45      23   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:21:45      24   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:45      25   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:45      26   29.47    0.00   14.74    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:45      27   27.08    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   55.21
08:21:45      28   26.60    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   56.38
08:21:45      29   29.90    0.00   15.46    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:21:45      30   28.87    0.00   15.46    1.03    0.00    0.00    0.00    0.00    0.00   54.64
08:21:45      31   25.00    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   53.12

08:21:45     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:46     all   27.39    0.00   17.22    1.79    0.00    0.00    0.00    0.00    0.00   53.60
08:21:46       0   28.87    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:46       1   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:46       2   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:21:46       3   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:46       4   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:46       5   25.00    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:46       6   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:46       7   26.80    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:21:46       8   27.08    0.00   16.67    3.12    0.00    0.00    0.00    0.00    0.00   53.12
08:21:46       9   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:46      10   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:46      11   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:46      12   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:21:46      13   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:46      14   27.84    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:46      15   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:46      16   25.77    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   54.64
08:21:46      17   27.66    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:46      18   26.80    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:21:46      19   27.66    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:21:46      20   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:46      21   27.66    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:46      22   29.17    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:46      23   27.08    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:46      24   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:46      25   27.66    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:46      26   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:46      27   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:46      28   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:46      29   27.08    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:46      30   26.04    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   55.21
08:21:46      31   25.81    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   55.91

08:21:46     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:47     all   27.02    0.00   17.14    1.64    0.00    0.00    0.00    0.00    0.00   54.20
08:21:47       0   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:47       1   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:47       2   29.17    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:47       3   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:47       4   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:47       5   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:47       6   27.66    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:47       7   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:47       8   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:47       9   26.60    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:47      10   28.72    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:47      11   27.66    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:21:47      12   27.08    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:47      13   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:47      14   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:47      15   25.77    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   54.64
08:21:47      16   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:47      17   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:47      18   26.60    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   55.32
08:21:47      19   26.80    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:47      20   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:47      21   26.80    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   54.64
08:21:47      22   25.27    0.00   16.48    2.20    0.00    0.00    0.00    0.00    0.00   56.04
08:21:47      23   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:47      24   25.53    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:47      25   24.49    0.00   20.41    3.06    0.00    0.00    0.00    0.00    0.00   52.04
08:21:47      26   25.26    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:47      27   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:47      28   26.04    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   55.21
08:21:47      29   25.53    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:21:47      30   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:47      31   27.08    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   54.17

08:21:47     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:48     all   26.72    0.00   17.38    1.61    0.00    0.00    0.00    0.00    0.00   54.29
08:21:48       0   28.42    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:48       1   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:48       2   25.53    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:48       3   25.53    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:48       4   27.96    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   54.84
08:21:48       5   27.08    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   55.21
08:21:48       6   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:48       7   27.37    0.00   16.84    3.16    0.00    0.00    0.00    0.00    0.00   52.63
08:21:48       8   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:21:48       9   25.00    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:48      10   27.08    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:48      11   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:21:48      12   25.26    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:21:48      13   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:48      14   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:48      15   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:48      16   27.66    0.00   14.89    2.13    0.00    0.00    0.00    0.00    0.00   55.32
08:21:48      17   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:48      18   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:48      19   25.26    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   55.79
08:21:48      20   26.04    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   55.21
08:21:48      21   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:48      22   25.26    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:48      23   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:48      24   29.17    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:48      25   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:48      26   26.32    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   55.79
08:21:48      27   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:48      28   25.81    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   55.91
08:21:48      29   27.08    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:48      30   26.80    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:48      31   26.88    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   55.91

08:21:48     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:49     all   27.29    0.00   17.35    1.53    0.00    0.00    0.00    0.00    0.00   53.83
08:21:49       0   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:49       1   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:49       2   26.60    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:21:49       3   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:21:49       4   26.80    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   54.64
08:21:49       5   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:49       6   28.57    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:21:49       7   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:49       8   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:49       9   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:49      10   26.04    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:49      11   28.42    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:49      12   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:49      13   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:49      14   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:49      15   26.88    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   55.91
08:21:49      16   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:49      17   27.84    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   54.64
08:21:49      18   27.27    0.00   18.18    1.01    0.00    0.00    0.00    0.00    0.00   53.54
08:21:49      19   27.66    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:21:49      20   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:21:49      21   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:49      22   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:49      23   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:49      24   28.87    0.00   15.46    1.03    0.00    0.00    0.00    0.00    0.00   54.64
08:21:49      25   29.17    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:49      26   24.47    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:21:49      27   25.77    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:49      28   25.77    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:49      29   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:49      30   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:49      31   25.51    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   53.06

08:21:49     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:50     all   27.24    0.00   17.57    1.72    0.00    0.00    0.00    0.00    0.00   53.47
08:21:50       0   29.90    0.00   15.46    3.09    0.00    0.00    0.00    0.00    0.00   51.55
08:21:50       1   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:21:50       2   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:21:50       3   28.12    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:50       4   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:50       5   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:50       6   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:50       7   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:50       8   25.51    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:21:50       9   26.53    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:21:50      10   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:50      11   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:50      12   26.80    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   54.64
08:21:50      13   25.25    0.00   20.20    2.02    0.00    0.00    0.00    0.00    0.00   52.53
08:21:50      14   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:50      15   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:50      16   26.53    0.00   19.39    1.02    0.00    0.00    0.00    0.00    0.00   53.06
08:21:50      17   29.59    0.00   16.33    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:21:50      18   29.17    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:50      19   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:50      20   29.17    0.00   14.58    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:50      21   26.60    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:50      22   25.00    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:50      23   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:50      24   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:50      25   25.26    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:50      26   28.42    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:50      27   27.84    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   54.64
08:21:50      28   26.53    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   54.08
08:21:50      29   27.55    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:21:50      30   26.80    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:50      31   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74

08:21:50     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:51     all   26.82    0.00   17.37    1.58    0.00    0.00    0.00    0.00    0.00   54.24
08:21:51       0   26.88    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   54.84
08:21:51       1   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:51       2   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:51       3   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:51       4   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:51       5   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:51       6   25.26    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:51       7   27.66    0.00   15.96    0.00    0.00    0.00    0.00    0.00    0.00   56.38
08:21:51       8   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:51       9   27.84    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:21:51      10   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:51      11   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:51      12   28.72    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:51      13   25.26    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:51      14   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:51      15   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:51      16   27.08    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   55.21
08:21:51      17   26.04    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:51      18   25.53    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:51      19   26.04    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:51      20   25.26    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:51      21   26.60    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:21:51      22   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:51      23   27.37    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   55.79
08:21:51      24   26.32    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   54.74
08:21:51      25   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:51      26   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:51      27   28.42    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:51      28   26.04    0.00   17.71    3.12    0.00    0.00    0.00    0.00    0.00   53.12
08:21:51      29   26.60    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   56.38
08:21:51      30   27.37    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   55.79
08:21:51      31   25.51    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   53.06

08:21:51     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:52     all   28.13    0.00   17.89    1.99    0.00    0.00    0.00    0.00    0.00   51.99
08:21:52       0   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:52       1   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:21:52       2   30.61    0.00   15.31    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:21:52       3   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:21:52       4   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:21:52       5   30.21    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:21:52       6   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:21:52       7   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:52       8   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:21:52       9   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:52      10   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:52      11   30.85    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   50.00
08:21:52      12   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:52      13   25.77    0.00   20.62    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:21:52      14   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:21:52      15   27.55    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:21:52      16   25.26    0.00   21.05    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:21:52      17   27.96    0.00   17.20    3.23    0.00    0.00    0.00    0.00    0.00   51.61
08:21:52      18   29.90    0.00   15.46    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:52      19   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:52      20   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:52      21   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:52      22   28.57    0.00   18.37    3.06    0.00    0.00    0.00    0.00    0.00   50.00
08:21:52      23   27.08    0.00   17.71    3.12    0.00    0.00    0.00    0.00    0.00   52.08
08:21:52      24   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:21:52      25   28.12    0.00   18.75    3.12    0.00    0.00    0.00    0.00    0.00   50.00
08:21:52      26   29.03    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:21:52      27   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:52      28   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:21:52      29   28.28    0.00   19.19    2.02    0.00    0.00    0.00    0.00    0.00   50.51
08:21:52      30   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:52      31   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68

08:21:52     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:53     all   27.49    0.00   17.06    1.70    0.00    0.00    0.00    0.00    0.00   53.74
08:21:53       0   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:53       1   29.90    0.00   15.46    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:53       2   28.72    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:53       3   25.53    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:53       4   27.08    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:53       5   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:53       6   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:53       7   27.96    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:21:53       8   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:53       9   29.59    0.00   16.33    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:21:53      10   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:21:53      11   25.00    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:53      12   27.55    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:21:53      13   29.79    0.00   13.83    0.00    0.00    0.00    0.00    0.00    0.00   56.38
08:21:53      14   25.26    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   54.74
08:21:53      15   29.47    0.00   14.74    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:53      16   26.80    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:53      17   26.04    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:53      18   28.57    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:21:53      19   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:53      20   26.60    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:53      21   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:53      22   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:53      23   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:21:53      24   25.26    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:53      25   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:53      26   28.28    0.00   17.17    2.02    0.00    0.00    0.00    0.00    0.00   52.53
08:21:53      27   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:53      28   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:53      29   29.47    0.00   14.74    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:53      30   27.08    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   55.21
08:21:53      31   29.79    0.00   14.89    1.06    0.00    0.00    0.00    0.00    0.00   54.26

08:21:53     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:54     all   27.37    0.00   17.50    1.66    0.00    0.00    0.00    0.00    0.00   53.47
08:21:54       0   27.08    0.00   17.71    3.12    0.00    0.00    0.00    0.00    0.00   52.08
08:21:54       1   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:21:54       2   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:54       3   25.77    0.00   18.56    3.09    0.00    0.00    0.00    0.00    0.00   52.58
08:21:54       4   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:21:54       5   25.77    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:54       6   25.26    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:54       7   26.04    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:54       8   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:54       9   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:54      10   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:21:54      11   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:21:54      12   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:21:54      13   27.55    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:21:54      14   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:54      15   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:54      16   27.55    0.00   17.35    1.02    0.00    0.00    0.00    0.00    0.00   54.08
08:21:54      17   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:54      18   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:21:54      19   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:54      20   27.84    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:54      21   28.57    0.00   16.33    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:21:54      22   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:54      23   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:54      24   25.77    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:54      25   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:54      26   29.17    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:54      27   27.55    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:21:54      28   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:54      29   27.08    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   55.21
08:21:54      30   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:54      31   25.77    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   54.64

08:21:54     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:55     all   27.65    0.00   17.40    1.66    0.00    0.00    0.00    0.00    0.00   53.29
08:21:55       0   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:55       1   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:55       2   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:55       3   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:55       4   27.55    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:21:55       5   26.60    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:21:55       6   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:21:55       7   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:55       8   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:55       9   29.29    0.00   17.17    2.02    0.00    0.00    0.00    0.00    0.00   51.52
08:21:55      10   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:55      11   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:21:55      12   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:55      13   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:55      14   28.57    0.00   16.33    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:21:55      15   28.87    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:21:55      16   28.28    0.00   18.18    1.01    0.00    0.00    0.00    0.00    0.00   52.53
08:21:55      17   27.84    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:55      18   28.87    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:55      19   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:55      20   28.42    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:55      21   27.84    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:21:55      22   28.87    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:55      23   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:55      24   29.17    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:55      25   26.60    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:55      26   26.04    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:55      27   25.77    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:55      28   27.08    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:55      29   29.59    0.00   15.31    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:21:55      30   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:55      31   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74

08:21:55     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:56     all   27.21    0.00   17.53    1.51    0.00    0.00    0.00    0.00    0.00   53.76
08:21:56       0   25.26    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:56       1   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:56       2   27.66    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:21:56       3   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:21:56       4   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:56       5   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:56       6   27.66    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:21:56       7   28.42    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:56       8   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:56       9   26.60    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:56      10   25.53    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:21:56      11   26.60    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:56      12   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:21:56      13   26.88    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   54.84
08:21:56      14   25.53    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:56      15   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:56      16   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:56      17   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:21:56      18   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:56      19   27.84    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:21:56      20   30.21    0.00   14.58    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:56      21   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:56      22   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:56      23   27.96    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   54.84
08:21:56      24   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:56      25   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:56      26   25.77    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   54.64
08:21:56      27   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:56      28   28.57    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:21:56      29   25.26    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:56      30   27.84    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:56      31   27.08    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   54.17

08:21:56     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:57     all   27.55    0.00   17.12    1.64    0.00    0.00    0.00    0.00    0.00   53.69
08:21:57       0   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:21:57       1   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:57       2   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:57       3   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:57       4   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:57       5   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:57       6   27.66    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:21:57       7   29.47    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:57       8   28.72    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:57       9   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:57      10   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:57      11   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:57      12   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:57      13   25.53    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:57      14   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:57      15   29.47    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:21:57      16   26.80    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:57      17   26.60    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:21:57      18   26.60    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:21:57      19   28.42    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:57      20   25.53    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:57      21   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:57      22   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:57      23   26.80    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   54.64
08:21:57      24   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:57      25   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:57      26   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:57      27   26.04    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   55.21
08:21:57      28   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:57      29   28.72    0.00   14.89    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:57      30   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:57      31   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68

08:21:57     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:58     all   27.38    0.00   17.11    1.79    0.00    0.00    0.00    0.00    0.00   53.72
08:21:58       0   27.96    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   54.84
08:21:58       1   26.04    0.00   18.75    3.12    0.00    0.00    0.00    0.00    0.00   52.08
08:21:58       2   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:58       3   28.87    0.00   15.46    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:58       4   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:58       5   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:58       6   26.80    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:58       7   26.04    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   55.21
08:21:58       8   26.80    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:58       9   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:58      10   28.87    0.00   15.46    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:58      11   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:58      12   27.55    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:21:58      13   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:58      14   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:58      15   28.57    0.00   16.33    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:21:58      16   26.60    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:58      17   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:58      18   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:21:58      19   25.26    0.00   17.89    3.16    0.00    0.00    0.00    0.00    0.00   53.68
08:21:58      20   28.57    0.00   16.33    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:21:58      21   25.53    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:21:58      22   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:58      23   25.81    0.00   18.28    0.00    0.00    0.00    0.00    0.00    0.00   55.91
08:21:58      24   29.17    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:58      25   26.60    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:21:58      26   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:58      27   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:58      28   29.17    0.00   14.58    1.04    0.00    0.00    0.00    0.00    0.00   55.21
08:21:58      29   29.90    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:21:58      30   25.77    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:21:58      31   28.12    0.00   16.67    3.12    0.00    0.00    0.00    0.00    0.00   52.08

08:21:58     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:21:59     all   27.31    0.00   17.67    1.60    0.00    0.00    0.00    0.00    0.00   53.41
08:21:59       0   29.59    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:21:59       1   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:21:59       2   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:59       3   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:21:59       4   26.60    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:21:59       5   25.26    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:59       6   26.80    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:21:59       7   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:59       8   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:59       9   26.80    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:21:59      10   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:21:59      11   26.60    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:21:59      12   30.21    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:21:59      13   27.84    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:21:59      14   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:59      15   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:21:59      16   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:59      17   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:21:59      18   26.04    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:21:59      19   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:59      20   28.72    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:59      21   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:59      22   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:21:59      23   25.26    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   54.74
08:21:59      24   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:21:59      25   26.53    0.00   19.39    1.02    0.00    0.00    0.00    0.00    0.00   53.06
08:21:59      26   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:21:59      27   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:21:59      28   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:21:59      29   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:21:59      30   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:21:59      31   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12

08:21:59     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:00     all   27.55    0.00   17.93    1.52    0.00    0.00    0.00    0.00    0.00   53.00
08:22:00       0   25.26    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:00       1   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:00       2   27.84    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:00       3   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:00       4   28.57    0.00   16.33    1.02    0.00    0.00    0.00    0.00    0.00   54.08
08:22:00       5   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:00       6   29.90    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:00       7   26.80    0.00   19.59    3.09    0.00    0.00    0.00    0.00    0.00   50.52
08:22:00       8   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:00       9   27.55    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:00      10   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:00      11   27.55    0.00   19.39    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:22:00      12   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:00      13   28.87    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:00      14   24.21    0.00   21.05    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:00      15   26.53    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:22:00      16   29.17    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:00      17   26.04    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:22:00      18   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:00      19   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:00      20   28.72    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:00      21   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:00      22   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:00      23   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:00      24   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:00      25   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:00      26   26.80    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:00      27   28.87    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:00      28   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:00      29   28.87    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:00      30   25.77    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:22:00      31   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17

08:22:00     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:01     all   26.86    0.00   18.04    1.63    0.00    0.00    0.00    0.00    0.00   53.47
08:22:01       0   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:01       1   27.55    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   53.06
08:22:01       2   28.87    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:01       3   25.00    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   55.21
08:22:01       4   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:01       5   25.26    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:01       6   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:01       7   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:01       8   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:01       9   25.26    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:01      10   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:01      11   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:01      12   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:01      13   25.00    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:01      14   26.80    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:01      15   27.66    0.00   17.02    0.00    0.00    0.00    0.00    0.00    0.00   55.32
08:22:01      16   26.53    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:22:01      17   26.04    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:01      18   25.26    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:01      19   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:01      20   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:01      21   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:01      22   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:01      23   25.51    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:22:01      24   26.04    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:01      25   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:01      26   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:01      27   30.21    0.00   15.62    3.12    0.00    0.00    0.00    0.00    0.00   51.04
08:22:01      28   26.80    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:22:01      29   25.26    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   55.79
08:22:01      30   25.53    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:22:01      31   28.12    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   54.17

08:22:01     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:02     all   27.25    0.00   17.41    1.64    0.00    0.00    0.00    0.00    0.00   53.70
08:22:02       0   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:02       1   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:02       2   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:02       3   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:02       4   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:02       5   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:02       6   29.90    0.00   15.46    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:02       7   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:02       8   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:02       9   27.66    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:22:02      10   28.12    0.00   17.71    3.12    0.00    0.00    0.00    0.00    0.00   51.04
08:22:02      11   26.88    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   54.84
08:22:02      12   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:02      13   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:02      14   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:02      15   26.04    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   54.17
08:22:02      16   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:02      17   29.17    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:02      18   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:02      19   25.26    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:02      20   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:02      21   26.80    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:22:02      22   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:02      23   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:02      24   29.47    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:02      25   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:02      26   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:02      27   27.66    0.00   14.89    1.06    0.00    0.00    0.00    0.00    0.00   56.38
08:22:02      28   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:02      29   25.81    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   54.84
08:22:02      30   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:02      31   25.00    0.00   18.48    1.09    0.00    0.00    0.00    0.00    0.00   55.43

08:22:02     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:03     all   27.72    0.00   17.62    1.56    0.00    0.00    0.00    0.00    0.00   53.10
08:22:03       0   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:03       1   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:03       2   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:03       3   29.47    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:03       4   29.59    0.00   17.35    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:22:03       5   27.84    0.00   18.56    3.09    0.00    0.00    0.00    0.00    0.00   50.52
08:22:03       6   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:03       7   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:03       8   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:03       9   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:03      10   26.04    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:03      11   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:03      12   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:03      13   25.51    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:22:03      14   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:03      15   26.80    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:03      16   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:03      17   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:03      18   28.87    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:03      19   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:03      20   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:03      21   28.72    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:03      22   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:03      23   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:03      24   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:03      25   27.55    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:03      26   29.59    0.00   16.33    1.02    0.00    0.00    0.00    0.00    0.00   53.06
08:22:03      27   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:03      28   29.17    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:03      29   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:03      30   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:03      31   27.55    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   53.06

08:22:03     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:04     all   27.96    0.00   17.25    1.72    0.00    0.00    0.00    0.00    0.00   53.07
08:22:04       0   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:04       1   27.55    0.00   19.39    3.06    0.00    0.00    0.00    0.00    0.00   50.00
08:22:04       2   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:04       3   28.28    0.00   18.18    1.01    0.00    0.00    0.00    0.00    0.00   52.53
08:22:04       4   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:04       5   29.47    0.00   14.74    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:04       6   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:04       7   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:04       8   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:04       9   31.25    0.00   14.58    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:04      10   30.53    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:04      11   27.55    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:22:04      12   28.57    0.00   17.35    3.06    0.00    0.00    0.00    0.00    0.00   51.02
08:22:04      13   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:04      14   28.28    0.00   17.17    2.02    0.00    0.00    0.00    0.00    0.00   52.53
08:22:04      15   29.59    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:04      16   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:04      17   29.17    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:04      18   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:04      19   28.87    0.00   15.46    1.03    0.00    0.00    0.00    0.00    0.00   54.64
08:22:04      20   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:04      21   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:04      22   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:04      23   27.84    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:22:04      24   28.28    0.00   17.17    2.02    0.00    0.00    0.00    0.00    0.00   52.53
08:22:04      25   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:04      26   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:04      27   26.60    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:04      28   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:04      29   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:04      30   27.84    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:04      31   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74

08:22:04     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:05     all   27.19    0.00   17.74    1.51    0.00    0.00    0.00    0.00    0.00   53.57
08:22:05       0   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:05       1   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:05       2   25.53    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:22:05       3   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:05       4   30.21    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:05       5   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:05       6   25.00    0.00   20.83    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:05       7   30.53    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:05       8   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:05       9   26.04    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:05      10   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:05      11   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:05      12   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:05      13   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:05      14   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:05      15   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:05      16   25.00    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:05      17   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:05      18   27.84    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:05      19   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:05      20   27.08    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   55.21
08:22:05      21   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:05      22   28.87    0.00   15.46    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:22:05      23   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:05      24   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:05      25   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:05      26   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:05      27   26.80    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:22:05      28   26.60    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:22:05      29   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:05      30   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:05      31   25.26    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   55.79

08:22:05     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:06     all   27.43    0.00   17.91    1.60    0.00    0.00    0.00    0.00    0.00   53.07
08:22:06       0   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:06       1   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:06       2   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:06       3   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:06       4   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:06       5   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:06       6   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:06       7   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:06       8   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:06       9   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:06      10   24.47    0.00   20.21    0.00    0.00    0.00    0.00    0.00    0.00   55.32
08:22:06      11   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:06      12   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:06      13   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:06      14   28.72    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:06      15   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:06      16   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:06      17   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:06      18   28.87    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:06      19   27.55    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   53.06
08:22:06      20   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:06      21   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:06      22   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:06      23   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:06      24   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:06      25   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:06      26   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:06      27   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:06      28   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:06      29   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:06      30   26.60    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:22:06      31   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55

08:22:06     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:07     all   27.47    0.00   17.63    1.64    0.00    0.00    0.00    0.00    0.00   53.26
08:22:07       0   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:07       1   28.72    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:07       2   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:07       3   24.47    0.00   20.21    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:07       4   25.81    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   55.91
08:22:07       5   25.26    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:07       6   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:07       7   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:07       8   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:07       9   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:07      10   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:07      11   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:07      12   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:07      13   27.66    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:22:07      14   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:07      15   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:07      16   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:07      17   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:07      18   29.17    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:07      19   26.60    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:07      20   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:07      21   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:07      22   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:07      23   28.87    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:07      24   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:07      25   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:07      26   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:07      27   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:07      28   27.84    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:07      29   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:07      30   26.04    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:07      31   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68

08:22:07     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:08     all   27.66    0.00   17.39    1.67    0.00    0.00    0.00    0.00    0.00   53.29
08:22:08       0   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:08       1   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:08       2   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:08       3   26.60    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:22:08       4   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:08       5   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:08       6   26.32    0.00   18.95    3.16    0.00    0.00    0.00    0.00    0.00   51.58
08:22:08       7   29.79    0.00   14.89    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:08       8   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:08       9   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:08      10   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:08      11   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:08      12   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:08      13   26.04    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:08      14   27.66    0.00   17.02    3.19    0.00    0.00    0.00    0.00    0.00   52.13
08:22:08      15   27.55    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   53.06
08:22:08      16   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:08      17   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:08      18   26.60    0.00   18.09    0.00    0.00    0.00    0.00    0.00    0.00   55.32
08:22:08      19   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:08      20   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:08      21   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:08      22   28.87    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:08      23   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:08      24   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:08      25   26.04    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:08      26   28.57    0.00   16.33    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:22:08      27   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:08      28   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:08      29   29.17    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:08      30   25.53    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   56.38
08:22:08      31   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17

08:22:08     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:09     all   27.45    0.00   17.81    1.54    0.00    0.00    0.00    0.00    0.00   53.20
08:22:09       0   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:09       1   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:09       2   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:09       3   26.04    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:09       4   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:09       5   29.17    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:09       6   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:09       7   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:09       8   25.77    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:09       9   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:09      10   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:09      11   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:09      12   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:09      13   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:09      14   29.17    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:09      15   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:09      16   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:09      17   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:09      18   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:09      19   27.37    0.00   16.84    3.16    0.00    0.00    0.00    0.00    0.00   52.63
08:22:09      20   24.21    0.00   21.05    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:09      21   28.42    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:09      22   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:09      23   25.77    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:09      24   27.84    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   54.64
08:22:09      25   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:09      26   26.88    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   54.84
08:22:09      27   27.55    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   53.06
08:22:09      28   25.53    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:09      29   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:09      30   28.72    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:09      31   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63

08:22:09     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:10     all   27.34    0.00   17.85    1.66    0.00    0.00    0.00    0.00    0.00   53.15
08:22:10       0   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:10       1   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:10       2   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:10       3   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:10       4   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:10       5   25.00    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:10       6   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:10       7   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:10       8   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:10       9   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:10      10   25.00    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:10      11   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:10      12   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:10      13   28.12    0.00   18.75    3.12    0.00    0.00    0.00    0.00    0.00   50.00
08:22:10      14   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:10      15   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:10      16   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:10      17   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:10      18   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:10      19   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:10      20   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:10      21   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:10      22   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:10      23   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:10      24   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:10      25   28.87    0.00   15.46    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:22:10      26   27.66    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:10      27   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:10      28   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:10      29   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:10      30   26.80    0.00   17.53    3.09    0.00    0.00    0.00    0.00    0.00   52.58
08:22:10      31   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12

08:22:10     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:11     all   28.21    0.00   17.29    1.47    0.00    0.00    0.00    0.00    0.00   53.02
08:22:11       0   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:11       1   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:11       2   29.47    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:11       3   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:11       4   29.59    0.00   17.35    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:22:11       5   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:11       6   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:11       7   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:11       8   29.17    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:11       9   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:11      10   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:11      11   29.47    0.00   15.79    3.16    0.00    0.00    0.00    0.00    0.00   51.58
08:22:11      12   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:11      13   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:11      14   28.28    0.00   18.18    2.02    0.00    0.00    0.00    0.00    0.00   51.52
08:22:11      15   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:11      16   31.25    0.00   13.54    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:11      17   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:11      18   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:11      19   29.17    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:11      20   25.77    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:11      21   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:11      22   29.47    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:11      23   29.47    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:11      24   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:11      25   26.60    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:11      26   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:11      27   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:11      28   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:11      29   26.80    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:11      30   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:11      31   25.53    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   54.26

08:22:11     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:12     all   27.65    0.00   17.79    1.67    0.00    0.00    0.00    0.00    0.00   52.89
08:22:12       0   27.96    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:12       1   26.88    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:12       2   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:12       3   26.04    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:12       4   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:12       5   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:12       6   28.87    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:12       7   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:12       8   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:12       9   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:12      10   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:12      11   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:12      12   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:12      13   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:12      14   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:12      15   26.60    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:12      16   27.84    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:12      17   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:12      18   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:12      19   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:12      20   30.21    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:12      21   28.87    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:12      22   26.32    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:12      23   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:12      24   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:12      25   29.47    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:12      26   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:12      27   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:12      28   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:12      29   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:12      30   26.60    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:22:12      31   26.80    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   53.61

08:22:12     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:13     all   27.66    0.00   17.45    1.57    0.00    0.00    0.00    0.00    0.00   53.32
08:22:13       0   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:13       1   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:13       2   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:13       3   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:13       4   30.53    0.00   14.74    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:13       5   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:13       6   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:13       7   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:13       8   29.47    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:13       9   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:13      10   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:13      11   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:13      12   28.72    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:13      13   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:13      14   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:13      15   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:13      16   26.60    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:13      17   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:13      18   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:13      19   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:13      20   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:13      21   28.72    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:13      22   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:13      23   30.21    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:13      24   26.04    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:13      25   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:13      26   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:13      27   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:13      28   26.53    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:22:13      29   25.81    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   55.91
08:22:13      30   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:13      31   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74

08:22:13     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:14     all   27.30    0.00   18.13    1.66    0.00    0.00    0.00    0.00    0.00   52.91
08:22:14       0   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:14       1   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:14       2   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:14       3   25.77    0.00   21.65    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:14       4   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:14       5   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:14       6   26.53    0.00   19.39    1.02    0.00    0.00    0.00    0.00    0.00   53.06
08:22:14       7   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:14       8   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:14       9   26.53    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:14      10   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:14      11   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:14      12   26.80    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:14      13   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:14      14   28.87    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:14      15   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:14      16   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:14      17   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:14      18   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:14      19   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:14      20   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:14      21   25.53    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:22:14      22   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:14      23   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:14      24   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:14      25   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:14      26   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:14      27   27.84    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:14      28   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:14      29   28.28    0.00   18.18    2.02    0.00    0.00    0.00    0.00    0.00   51.52
08:22:14      30   25.53    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:22:14      31   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17

08:22:14     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:15     all   28.12    0.00   17.99    1.49    0.00    0.00    0.00    0.00    0.00   52.39
08:22:15       0   29.59    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:22:15       1   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:15       2   26.80    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:15       3   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:15       4   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:15       5   29.29    0.00   18.18    2.02    0.00    0.00    0.00    0.00    0.00   50.51
08:22:15       6   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:15       7   27.84    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:15       8   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:15       9   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:15      10   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:15      11   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:15      12   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:15      13   25.77    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:15      14   30.93    0.00   15.46    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:15      15   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:15      16   28.72    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:15      17   28.28    0.00   19.19    2.02    0.00    0.00    0.00    0.00    0.00   50.51
08:22:15      18   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:15      19   26.04    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:15      20   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:15      21   25.77    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:15      22   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:15      23   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:15      24   30.93    0.00   15.46    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:15      25   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:15      26   29.59    0.00   16.33    1.02    0.00    0.00    0.00    0.00    0.00   53.06
08:22:15      27   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:15      28   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:15      29   29.17    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:15      30   25.77    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:15      31   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55

08:22:15     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:16     all   27.59    0.00   17.56    1.74    0.00    0.00    0.00    0.00    0.00   53.11
08:22:16       0   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:16       1   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:16       2   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:16       3   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:16       4   27.55    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   53.06
08:22:16       5   26.88    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:16       6   26.88    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   54.84
08:22:16       7   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:16       8   26.60    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:16       9   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:16      10   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:16      11   27.66    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:16      12   27.55    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:16      13   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:16      14   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:16      15   30.93    0.00   14.43    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:16      16   25.77    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:16      17   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:16      18   29.17    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:16      19   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:16      20   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:16      21   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:16      22   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:16      23   27.66    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:16      24   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:16      25   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:16      26   26.60    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:16      27   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:16      28   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:16      29   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:16      30   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:16      31   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12

08:22:16     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:17     all   27.89    0.00   17.87    1.52    0.00    0.00    0.00    0.00    0.00   52.71
08:22:17       0   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:17       1   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:17       2   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:17       3   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:17       4   29.03    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:17       5   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:17       6   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:17       7   31.58    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:17       8   29.59    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:17       9   28.57    0.00   17.35    1.02    0.00    0.00    0.00    0.00    0.00   53.06
08:22:17      10   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:17      11   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:17      12   25.26    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:17      13   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:17      14   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:17      15   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:17      16   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:17      17   25.77    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:17      18   27.55    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:17      19   27.55    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:17      20   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:17      21   29.90    0.00   16.49    3.09    0.00    0.00    0.00    0.00    0.00   50.52
08:22:17      22   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:17      23   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:17      24   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:17      25   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:17      26   28.12    0.00   17.71    3.12    0.00    0.00    0.00    0.00    0.00   51.04
08:22:17      27   27.55    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:17      28   27.84    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:17      29   26.88    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:17      30   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:17      31   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74

08:22:17     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:18     all   27.97    0.00   17.93    1.56    0.00    0.00    0.00    0.00    0.00   52.54
08:22:18       0   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:18       1   26.32    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:18       2   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:18       3   28.57    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:22:18       4   25.26    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:18       5   28.57    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:22:18       6   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:18       7   28.57    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:18       8   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:18       9   29.90    0.00   15.46    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:18      10   30.00    0.00   18.00    2.00    0.00    0.00    0.00    0.00    0.00   50.00
08:22:18      11   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:18      12   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:18      13   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:18      14   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:18      15   26.04    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:18      16   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:18      17   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:18      18   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:18      19   26.60    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:18      20   29.29    0.00   17.17    2.02    0.00    0.00    0.00    0.00    0.00   51.52
08:22:18      21   26.80    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:18      22   27.84    0.00   17.53    3.09    0.00    0.00    0.00    0.00    0.00   51.55
08:22:18      23   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:18      24   29.90    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:18      25   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:18      26   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:18      27   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:18      28   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:18      29   28.00    0.00   18.00    3.00    0.00    0.00    0.00    0.00    0.00   51.00
08:22:18      30   26.80    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:18      31   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12

08:22:18     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:19     all   27.63    0.00   17.67    1.68    0.00    0.00    0.00    0.00    0.00   53.02
08:22:19       0   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:19       1   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:19       2   30.53    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:19       3   28.57    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:22:19       4   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:19       5   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:19       6   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:19       7   27.96    0.00   16.13    2.15    0.00    0.00    0.00    0.00    0.00   53.76
08:22:19       8   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:19       9   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:19      10   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:19      11   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:19      12   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:19      13   29.79    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:19      14   25.53    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:22:19      15   29.47    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:19      16   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:19      17   24.74    0.00   20.62    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:19      18   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:19      19   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:19      20   26.09    0.00   18.48    1.09    0.00    0.00    0.00    0.00    0.00   54.35
08:22:19      21   26.60    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:22:19      22   24.47    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:22:19      23   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:19      24   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:19      25   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:19      26   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:19      27   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:19      28   30.85    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:22:19      29   26.88    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   54.84
08:22:19      30   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:19      31   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58

08:22:19     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:20     all   27.59    0.00   17.77    1.54    0.00    0.00    0.00    0.00    0.00   53.09
08:22:20       0   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:20       1   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:20       2   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:20       3   27.08    0.00   18.75    3.12    0.00    0.00    0.00    0.00    0.00   51.04
08:22:20       4   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:20       5   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:20       6   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:20       7   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:20       8   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:20       9   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:20      10   25.26    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:20      11   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:20      12   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:20      13   27.55    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   53.06
08:22:20      14   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:20      15   25.00    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:20      16   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:20      17   28.72    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:20      18   27.96    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   54.84
08:22:20      19   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:20      20   27.55    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:20      21   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:20      22   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:20      23   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:20      24   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:20      25   25.26    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:20      26   28.42    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:20      27   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:20      28   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:20      29   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:20      30   25.77    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:20      31   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68

08:22:20     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:21     all   28.35    0.00   17.21    1.57    0.00    0.00    0.00    0.00    0.00   52.87
08:22:21       0   30.93    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:21       1   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:21       2   28.87    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:21       3   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:21       4   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:21       5   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:21       6   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:21       7   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:21       8   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:21       9   29.90    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:21      10   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:21      11   30.21    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:21      12   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:21      13   29.79    0.00   17.02    0.00    0.00    0.00    0.00    0.00    0.00   53.19
08:22:21      14   27.66    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:22:21      15   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:21      16   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:21      17   30.21    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:21      18   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:21      19   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:21      20   26.60    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:22:21      21   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:21      22   30.21    0.00   16.67    3.12    0.00    0.00    0.00    0.00    0.00   50.00
08:22:21      23   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:21      24   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:21      25   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:21      26   28.72    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:21      27   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:21      28   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:21      29   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:21      30   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:21      31   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17

08:22:21     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:22     all   27.99    0.00   17.56    1.63    0.00    0.00    0.00    0.00    0.00   52.82
08:22:22       0   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:22       1   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:22       2   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:22       3   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:22       4   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:22       5   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:22       6   29.29    0.00   17.17    2.02    0.00    0.00    0.00    0.00    0.00   51.52
08:22:22       7   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:22       8   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:22       9   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:22      10   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:22      11   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:22      12   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:22      13   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:22      14   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:22      15   29.47    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:22      16   28.72    0.00   15.96    0.00    0.00    0.00    0.00    0.00    0.00   55.32
08:22:22      17   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:22      18   30.21    0.00   14.58    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:22      19   29.47    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:22      20   26.04    0.00   18.75    3.12    0.00    0.00    0.00    0.00    0.00   52.08
08:22:22      21   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:22      22   28.57    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:22      23   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:22      24   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:22      25   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:22      26   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:22      27   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:22      28   26.80    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:22      29   27.55    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:22      30   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:22      31   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74

08:22:22     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:23     all   27.40    0.00   18.18    1.73    0.00    0.00    0.00    0.00    0.00   52.69
08:22:23       0   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:23       1   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:23       2   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:23       3   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:23       4   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:23       5   27.84    0.00   18.56    3.09    0.00    0.00    0.00    0.00    0.00   50.52
08:22:23       6   26.60    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:23       7   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:23       8   28.72    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:23       9   26.32    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:23      10   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:23      11   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:23      12   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:23      13   26.60    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:23      14   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:23      15   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:23      16   27.55    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:23      17   27.55    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:23      18   28.57    0.00   17.35    1.02    0.00    0.00    0.00    0.00    0.00   53.06
08:22:23      19   27.55    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:23      20   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:23      21   26.80    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:22:23      22   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:23      23   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:23      24   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:23      25   25.77    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:23      26   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:23      27   28.87    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:23      28   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:23      29   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:23      30   27.84    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:23      31   25.00    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   52.08

08:22:23     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:24     all   28.18    0.00   17.75    1.44    0.00    0.00    0.00    0.00    0.00   52.63
08:22:24       0   29.59    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   51.02
08:22:24       1   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:24       2   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:24       3   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:24       4   29.90    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:24       5   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:24       6   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:24       7   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:24       8   29.90    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:24       9   26.88    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   54.84
08:22:24      10   29.47    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:24      11   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:24      12   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:24      13   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:24      14   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:24      15   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:24      16   27.66    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:24      17   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:24      18   25.26    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:24      19   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:24      20   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:24      21   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:24      22   28.72    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:22:24      23   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:24      24   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:24      25   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:24      26   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:24      27   29.03    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:24      28   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:24      29   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:24      30   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:24      31   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58

08:22:24     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:25     all   27.43    0.00   17.71    1.58    0.00    0.00    0.00    0.00    0.00   53.28
08:22:25       0   29.47    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:25       1   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:25       2   29.79    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:25       3   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:25       4   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:25       5   27.96    0.00   17.20    2.15    0.00    0.00    0.00    0.00    0.00   52.69
08:22:25       6   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:25       7   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:25       8   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:25       9   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:25      10   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:25      11   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:25      12   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:25      13   25.53    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:25      14   29.03    0.00   16.13    2.15    0.00    0.00    0.00    0.00    0.00   52.69
08:22:25      15   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:25      16   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:25      17   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:25      18   24.47    0.00   20.21    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:25      19   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:25      20   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:25      21   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:25      22   25.00    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:25      23   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:25      24   25.53    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:25      25   26.60    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   55.32
08:22:25      26   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:25      27   25.77    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:25      28   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:25      29   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:25      30   28.72    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:25      31   26.88    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   54.84

08:22:25     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:26     all   28.46    0.00   18.14    1.58    0.00    0.00    0.00    0.00    0.00   51.81
08:22:26       0   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:26       1   29.29    0.00   18.18    3.03    0.00    0.00    0.00    0.00    0.00   49.49
08:22:26       2   28.12    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:22:26       3   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:26       4   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:26       5   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:26       6   26.32    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:26       7   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:26       8   29.47    0.00   16.84    0.00    0.00    0.00    0.00    0.00    0.00   53.68
08:22:26       9   26.80    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:26      10   30.61    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:22:26      11   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:26      12   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:26      13   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:26      14   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:26      15   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:26      16   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:26      17   29.59    0.00   17.35    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:22:26      18   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:26      19   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:26      20   26.04    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:26      21   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:26      22   29.90    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:26      23   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:26      24   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:26      25   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:22:26      26   30.61    0.00   16.33    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:26      27   27.55    0.00   20.41    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:22:26      28   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:26      29   28.28    0.00   18.18    2.02    0.00    0.00    0.00    0.00    0.00   51.52
08:22:26      30   26.53    0.00   20.41    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:26      31   28.12    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   54.17

08:22:26     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:27     all   28.23    0.00   17.86    1.50    0.00    0.00    0.00    0.00    0.00   52.40
08:22:27       0   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:27       1   29.17    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:22:27       2   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:27       3   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:27       4   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:27       5   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:27       6   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:27       7   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:27       8   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:27       9   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:27      10   25.81    0.00   19.35    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:27      11   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:27      12   28.72    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:27      13   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:27      14   25.53    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:27      15   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:27      16   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:27      17   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:27      18   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:27      19   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:27      20   29.59    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:27      21   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:27      22   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:27      23   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:27      24   31.25    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:27      25   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:27      26   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:27      27   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:27      28   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:27      29   29.79    0.00   15.96    0.00    0.00    0.00    0.00    0.00    0.00   54.26
08:22:27      30   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:27      31   29.17    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   53.12

08:22:27     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:28     all   27.91    0.00   17.83    1.58    0.00    0.00    0.00    0.00    0.00   52.69
08:22:28       0   26.80    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:28       1   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:28       2   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:28       3   28.72    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:28       4   29.59    0.00   17.35    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:22:28       5   28.72    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:28       6   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:28       7   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:22:28       8   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:28       9   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:28      10   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:28      11   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:28      12   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:28      13   26.32    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:28      14   30.53    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:28      15   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:28      16   25.26    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:28      17   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:28      18   25.26    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:28      19   26.04    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:28      20   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:28      21   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:28      22   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:28      23   29.03    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:28      24   25.26    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:28      25   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:28      26   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:28      27   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:28      28   27.37    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:28      29   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:28      30   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:28      31   29.79    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   53.19

08:22:28     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:29     all   27.89    0.00   18.51    1.55    0.00    0.00    0.00    0.00    0.00   52.05
08:22:29       0   28.57    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:22:29       1   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:29       2   25.51    0.00   21.43    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:29       3   28.87    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:22:29       4   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:29       5   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:29       6   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:29       7   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:29       8   26.53    0.00   20.41    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:29       9   27.27    0.00   19.19    2.02    0.00    0.00    0.00    0.00    0.00   51.52
08:22:29      10   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:29      11   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:29      12   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:29      13   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:29      14   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:29      15   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:29      16   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:29      17   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:29      18   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:22:29      19   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:29      20   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:29      21   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:29      22   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:29      23   27.55    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:29      24   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:29      25   25.77    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   53.61
08:22:29      26   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:29      27   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:29      28   28.57    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:22:29      29   28.87    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:29      30   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:29      31   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12

08:22:29     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:30     all   27.65    0.00   17.90    1.68    0.00    0.00    0.00    0.00    0.00   52.77
08:22:30       0   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:30       1   28.72    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:22:30       2   27.17    0.00   17.39    1.09    0.00    0.00    0.00    0.00    0.00   54.35
08:22:30       3   25.53    0.00   20.21    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:30       4   26.32    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:30       5   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:30       6   27.96    0.00   17.20    2.15    0.00    0.00    0.00    0.00    0.00   52.69
08:22:30       7   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:30       8   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:30       9   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:30      10   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:30      11   27.96    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:30      12   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:30      13   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:30      14   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:30      15   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:30      16   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:30      17   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:30      18   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:30      19   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:30      20   25.26    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:30      21   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:30      22   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:22:30      23   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:30      24   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:30      25   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:30      26   29.17    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:30      27   25.81    0.00   19.35    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:30      28   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:30      29   26.04    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:30      30   27.66    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   54.26
08:22:30      31   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68

08:22:30     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:31     all   27.92    0.00   17.51    1.51    0.00    0.00    0.00    0.00    0.00   53.06
08:22:31       0   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:31       1   30.85    0.00   13.83    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:31       2   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:31       3   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:31       4   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:31       5   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:31       6   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:31       7   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:31       8   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:31       9   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:31      10   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:31      11   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:31      12   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:31      13   29.79    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:31      14   27.96    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:31      15   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:31      16   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:31      17   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:31      18   26.60    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:31      19   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:31      20   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:31      21   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:31      22   26.04    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:31      23   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:31      24   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:31      25   29.79    0.00   14.89    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:31      26   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:31      27   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:31      28   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:31      29   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:31      30   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:31      31   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12

08:22:31     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:32     all   27.80    0.00   17.92    1.58    0.00    0.00    0.00    0.00    0.00   52.71
08:22:32       0   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:22:32       1   27.37    0.00   18.95    0.00    0.00    0.00    0.00    0.00    0.00   53.68
08:22:32       2   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:32       3   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:32       4   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:32       5   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:32       6   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:32       7   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:32       8   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:32       9   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:32      10   25.53    0.00   20.21    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:32      11   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:32      12   26.60    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:32      13   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:32      14   26.32    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:32      15   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:32      16   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:32      17   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:32      18   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:32      19   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:32      20   27.55    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:32      21   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:32      22   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:32      23   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:32      24   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:32      25   29.47    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:32      26   25.26    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:32      27   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:32      28   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:32      29   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:32      30   29.79    0.00   14.89    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:32      31   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04

08:22:32     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:33     all   28.17    0.00   18.05    1.69    0.00    0.00    0.00    0.00    0.00   52.09
08:22:33       0   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:33       1   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:33       2   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:33       3   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:33       4   27.55    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:33       5   29.90    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:33       6   28.87    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:33       7   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:33       8   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:33       9   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:33      10   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:33      11   30.21    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:22:33      12   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:33      13   28.28    0.00   19.19    2.02    0.00    0.00    0.00    0.00    0.00   50.51
08:22:33      14   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:33      15   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:33      16   29.59    0.00   17.35    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:22:33      17   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:33      18   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:33      19   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:33      20   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:33      21   27.55    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:33      22   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:33      23   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:33      24   29.47    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:33      25   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:33      26   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:33      27   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:33      28   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:33      29   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:33      30   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:33      31   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08

08:22:33     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:34     all   28.05    0.00   17.90    1.57    0.00    0.00    0.00    0.00    0.00   52.48
08:22:34       0   29.47    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:34       1   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:34       2   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:34       3   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:34       4   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:34       5   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:34       6   29.17    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:22:34       7   26.80    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:34       8   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:34       9   26.60    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:34      10   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:34      11   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:34      12   30.53    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:34      13   26.04    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:34      14   29.90    0.00   17.53    3.09    0.00    0.00    0.00    0.00    0.00   49.48
08:22:34      15   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:34      16   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:34      17   30.21    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:34      18   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:34      19   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:34      20   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:34      21   25.77    0.00   20.62    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:34      22   26.32    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:34      23   26.60    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:34      24   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:34      25   29.90    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:34      26   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:34      27   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:34      28   27.37    0.00   17.89    0.00    0.00    0.00    0.00    0.00    0.00   54.74
08:22:34      29   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:34      30   28.12    0.00   17.71    0.00    0.00    0.00    0.00    0.00    0.00   54.17
08:22:34      31   25.81    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   54.84

08:22:34     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:35     all   28.12    0.00   17.35    1.54    0.00    0.00    0.00    0.00    0.00   52.99
08:22:35       0   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:35       1   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:35       2   27.96    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:35       3   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:35       4   30.85    0.00   14.89    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:35       5   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:35       6   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:35       7   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:35       8   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:35       9   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:35      10   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:35      11   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:35      12   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:35      13   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:35      14   26.88    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   54.84
08:22:35      15   26.60    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:35      16   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:35      17   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:35      18   29.47    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:35      19   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:35      20   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:35      21   28.72    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:35      22   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:35      23   28.87    0.00   16.49    3.09    0.00    0.00    0.00    0.00    0.00   51.55
08:22:35      24   28.72    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:35      25   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:35      26   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:35      27   27.55    0.00   19.39    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:22:35      28   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:35      29   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:35      30   26.32    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   54.74
08:22:35      31   29.90    0.00   15.46    1.03    0.00    0.00    0.00    0.00    0.00   53.61

08:22:35     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:36     all   28.42    0.00   17.99    1.49    0.00    0.00    0.00    0.00    0.00   52.09
08:22:36       0   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:36       1   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:36       2   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:36       3   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:36       4   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:36       5   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:36       6   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:36       7   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:36       8   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:36       9   30.21    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:22:36      10   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:36      11   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:36      12   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:36      13   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:36      14   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:36      15   30.21    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:22:36      16   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:36      17   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:36      18   26.53    0.00   20.41    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:22:36      19   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:36      20   29.59    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:36      21   30.53    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:22:36      22   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:36      23   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:36      24   27.55    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:36      25   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:36      26   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:36      27   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:36      28   27.84    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   53.61
08:22:36      29   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:36      30   29.47    0.00   16.84    0.00    0.00    0.00    0.00    0.00    0.00   53.68
08:22:36      31   30.21    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   52.08

08:22:36     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:37     all   28.04    0.00   17.51    1.68    0.00    0.00    0.00    0.00    0.00   52.76
08:22:37       0   28.57    0.00   15.38    1.10    0.00    0.00    0.00    0.00    0.00   54.95
08:22:37       1   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:37       2   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:37       3   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:37       4   27.37    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:37       5   30.53    0.00   14.74    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:37       6   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:37       7   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:37       8   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:37       9   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:37      10   26.60    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:37      11   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:37      12   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:37      13   27.96    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:37      14   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:37      15   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:37      16   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:37      17   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:37      18   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:37      19   27.96    0.00   16.13    2.15    0.00    0.00    0.00    0.00    0.00   53.76
08:22:37      20   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:37      21   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:37      22   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:37      23   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:37      24   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:37      25   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:37      26   24.47    0.00   20.21    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:37      27   29.17    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:37      28   25.81    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   54.84
08:22:37      29   29.47    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:37      30   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:37      31   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55

08:22:37     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:38     all   28.10    0.00   17.99    1.64    0.00    0.00    0.00    0.00    0.00   52.27
08:22:38       0   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:38       1   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:38       2   27.66    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:22:38       3   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:38       4   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:38       5   26.32    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:38       6   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:38       7   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:38       8   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:38       9   31.58    0.00   14.74    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:38      10   30.21    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:38      11   26.32    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:38      12   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:38      13   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:38      14   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:38      15   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:38      16   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:38      17   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:38      18   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:38      19   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:38      20   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:38      21   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:38      22   26.80    0.00   20.62    3.09    0.00    0.00    0.00    0.00    0.00   49.48
08:22:38      23   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:38      24   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:38      25   26.04    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:38      26   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:38      27   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:38      28   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:38      29   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:38      30   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:38      31   27.84    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   53.61

08:22:38     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:39     all   28.38    0.00   18.21    1.44    0.00    0.00    0.00    0.00    0.00   51.97
08:22:39       0   26.32    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:39       1   28.42    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:22:39       2   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:39       3   28.87    0.00   18.56    3.09    0.00    0.00    0.00    0.00    0.00   49.48
08:22:39       4   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:39       5   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:39       6   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:39       7   29.79    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:39       8   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:39       9   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:39      10   26.60    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:39      11   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:39      12   30.11    0.00   16.13    0.00    0.00    0.00    0.00    0.00    0.00   53.76
08:22:39      13   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:39      14   28.12    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:22:39      15   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:39      16   28.57    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:39      17   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:39      18   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:39      19   30.53    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:39      20   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:39      21   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:39      22   30.21    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:22:39      23   25.53    0.00   20.21    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:39      24   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:39      25   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:39      26   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:39      27   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:39      28   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:39      29   27.55    0.00   19.39    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:22:39      30   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:39      31   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12

08:22:39     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:40     all   28.33    0.00   17.61    1.57    0.00    0.00    0.00    0.00    0.00   52.49
08:22:40       0   29.79    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:22:40       1   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:40       2   26.32    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:40       3   29.79    0.00   15.96    0.00    0.00    0.00    0.00    0.00    0.00   54.26
08:22:40       4   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:40       5   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:40       6   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:40       7   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:40       8   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:40       9   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:40      10   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:40      11   28.72    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:22:40      12   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:40      13   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:40      14   27.55    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:40      15   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:40      16   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:40      17   29.90    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:40      18   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:40      19   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:40      20   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:40      21   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:40      22   27.66    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:40      23   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:40      24   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:40      25   29.79    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:22:40      26   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:40      27   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:40      28   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:40      29   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:40      30   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:40      31   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58

08:22:40     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:41     all   27.81    0.00   17.88    1.67    0.00    0.00    0.00    0.00    0.00   52.64
08:22:41       0   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:41       1   27.66    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:22:41       2   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:41       3   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:41       4   25.26    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:41       5   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:41       6   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:41       7   28.42    0.00   16.84    3.16    0.00    0.00    0.00    0.00    0.00   51.58
08:22:41       8   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:41       9   28.72    0.00   17.02    0.00    0.00    0.00    0.00    0.00    0.00   54.26
08:22:41      10   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:22:41      11   31.25    0.00   14.58    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:41      12   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:41      13   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:41      14   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:41      15   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:41      16   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:41      17   28.42    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:41      18   27.96    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   54.84
08:22:41      19   30.53    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:41      20   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:41      21   27.96    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:41      22   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:41      23   26.53    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:41      24   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:41      25   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:41      26   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:41      27   26.32    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:41      28   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:41      29   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:41      30   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:41      31   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63

08:22:41     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:42     all   28.03    0.00   18.16    1.48    0.00    0.00    0.00    0.00    0.00   52.33
08:22:42       0   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:42       1   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:42       2   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:42       3   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:42       4   29.03    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:22:42       5   29.79    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:22:42       6   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:42       7   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:42       8   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:42       9   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:42      10   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:42      11   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:42      12   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:42      13   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:42      14   29.03    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:42      15   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:42      16   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:42      17   25.53    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:42      18   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:42      19   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:42      20   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:42      21   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:42      22   29.90    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:42      23   27.96    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:22:42      24   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:42      25   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:42      26   26.88    0.00   18.28    2.15    0.00    0.00    0.00    0.00    0.00   52.69
08:22:42      27   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:42      28   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:42      29   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:42      30   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:42      31   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04

08:22:42     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:43     all   28.59    0.00   17.76    1.63    0.00    0.00    0.00    0.00    0.00   52.02
08:22:43       0   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:43       1   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:43       2   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:43       3   29.90    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:43       4   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:43       5   29.90    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:43       6   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:43       7   29.79    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:43       8   31.25    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:22:43       9   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:22:43      10   27.84    0.00   19.59    3.09    0.00    0.00    0.00    0.00    0.00   49.48
08:22:43      11   26.53    0.00   21.43    1.02    0.00    0.00    0.00    0.00    0.00   51.02
08:22:43      12   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:22:43      13   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:43      14   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:43      15   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:43      16   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:43      17   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:43      18   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:43      19   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:43      20   29.90    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:43      21   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:43      22   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:43      23   30.21    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:43      24   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:43      25   31.63    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   48.98
08:22:43      26   26.80    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:43      27   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:43      28   28.72    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:43      29   25.53    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:43      30   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:43      31   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74

08:22:43     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:44     all   28.52    0.00   18.02    1.59    0.00    0.00    0.00    0.00    0.00   51.88
08:22:44       0   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:44       1   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:44       2   26.53    0.00   20.41    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:44       3   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:44       4   29.29    0.00   17.17    2.02    0.00    0.00    0.00    0.00    0.00   51.52
08:22:44       5   29.90    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:44       6   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:44       7   29.90    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:44       8   30.30    0.00   18.18    2.02    0.00    0.00    0.00    0.00    0.00   49.49
08:22:44       9   29.90    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:22:44      10   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:44      11   26.04    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:44      12   30.53    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:44      13   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:44      14   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:44      15   25.26    0.00   21.05    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:44      16   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:44      17   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:44      18   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:44      19   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:44      20   26.32    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:44      21   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:44      22   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:44      23   28.57    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:44      24   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:44      25   29.90    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:44      26   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:44      27   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:44      28   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:44      29   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:44      30   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:44      31   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12

08:22:44     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:45     all   29.03    0.00   18.12    1.59    0.00    0.00    0.00    0.00    0.00   51.27
08:22:45       0   30.21    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:22:45       1   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:45       2   28.72    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   51.06
08:22:45       3   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:45       4   32.63    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   50.53
08:22:45       5   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:45       6   30.93    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:22:45       7   27.84    0.00   20.62    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:22:45       8   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:45       9   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:45      10   30.21    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:22:45      11   30.21    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:45      12   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:45      13   29.90    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:22:45      14   26.60    0.00   20.21    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:22:45      15   28.57    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:22:45      16   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:45      17   26.80    0.00   20.62    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:45      18   31.58    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:45      19   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:45      20   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:45      21   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:45      22   28.87    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:22:45      23   30.61    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   48.98
08:22:45      24   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:45      25   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:45      26   30.53    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:45      27   30.53    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:45      28   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:45      29   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:45      30   28.57    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:22:45      31   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58

08:22:45     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:46     all   28.55    0.00   18.03    1.56    0.00    0.00    0.00    0.00    0.00   51.86
08:22:46       0   35.05    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   46.39
08:22:46       1   31.25    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:46       2   28.57    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:22:46       3   27.66    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:46       4   28.87    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:22:46       5   29.90    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:46       6   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:46       7   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:46       8   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:46       9   29.90    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:46      10   29.03    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:22:46      11   28.87    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:22:46      12   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:46      13   30.85    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:22:46      14   27.55    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:46      15   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:46      16   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:46      17   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:46      18   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:46      19   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:46      20   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:46      21   26.04    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:46      22   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:46      23   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:46      24   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:46      25   25.77    0.00   20.62    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:46      26   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:46      27   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:46      28   28.12    0.00   17.71    0.00    0.00    0.00    0.00    0.00    0.00   54.17
08:22:46      29   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:46      30   29.90    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:46      31   27.96    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   54.84

08:22:46     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:47     all   28.05    0.00   18.03    1.52    0.00    0.00    0.00    0.00    0.00   52.41
08:22:47       0   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:47       1   29.79    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:47       2   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:22:47       3   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:47       4   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:47       5   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:47       6   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:47       7   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:47       8   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:47       9   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:47      10   27.84    0.00   19.59    3.09    0.00    0.00    0.00    0.00    0.00   49.48
08:22:47      11   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:47      12   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:47      13   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:47      14   25.26    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:47      15   29.03    0.00   16.13    2.15    0.00    0.00    0.00    0.00    0.00   52.69
08:22:47      16   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:47      17   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:47      18   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:47      19   27.96    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:47      20   30.53    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:47      21   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:47      22   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:47      23   27.96    0.00   17.20    2.15    0.00    0.00    0.00    0.00    0.00   52.69
08:22:47      24   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:47      25   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:47      26   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:22:47      27   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:47      28   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:47      29   27.66    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:47      30   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:47      31   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58

08:22:47     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:48     all   28.18    0.00   18.62    1.53    0.00    0.00    0.00    0.00    0.00   51.67
08:22:48       0   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:48       1   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:48       2   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:48       3   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:48       4   26.80    0.00   20.62    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:48       5   29.59    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:48       6   29.90    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:48       7   29.90    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:22:48       8   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:48       9   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:48      10   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:48      11   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:48      12   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:48      13   30.53    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:48      14   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:48      15   29.59    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:22:48      16   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:48      17   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:48      18   27.37    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:48      19   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:48      20   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:48      21   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:48      22   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:48      23   25.53    0.00   20.21    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:48      24   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:48      25   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:48      26   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:48      27   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:48      28   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:48      29   27.55    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:48      30   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:48      31   26.60    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   52.13

08:22:48     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:49     all   28.07    0.00   18.13    1.57    0.00    0.00    0.00    0.00    0.00   52.23
08:22:49       0   30.21    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:22:49       1   29.79    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   51.06
08:22:49       2   28.57    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:22:49       3   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:49       4   30.85    0.00   14.89    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:49       5   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:49       6   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:49       7   29.17    0.00   16.67    3.12    0.00    0.00    0.00    0.00    0.00   51.04
08:22:49       8   27.55    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:49       9   26.60    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:49      10   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:49      11   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:22:49      12   26.32    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:49      13   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:49      14   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:22:49      15   26.88    0.00   18.28    2.15    0.00    0.00    0.00    0.00    0.00   52.69
08:22:49      16   25.77    0.00   20.62    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:49      17   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:49      18   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:49      19   26.04    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:49      20   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:49      21   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:49      22   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:49      23   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:49      24   31.91    0.00   14.89    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:22:49      25   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:49      26   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:49      27   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:49      28   25.26    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   53.68
08:22:49      29   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:49      30   26.60    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:49      31   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12

08:22:49     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:50     all   27.56    0.00   18.41    1.55    0.00    0.00    0.00    0.00    0.00   52.49
08:22:50       0   26.88    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:50       1   28.42    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:50       2   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:50       3   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:50       4   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:50       5   27.66    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:22:50       6   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:50       7   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:50       8   27.17    0.00   19.57    1.09    0.00    0.00    0.00    0.00    0.00   52.17
08:22:50       9   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:50      10   26.60    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:50      11   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:50      12   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:50      13   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:50      14   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:50      15   26.32    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:50      16   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:50      17   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:50      18   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:50      19   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:50      20   26.60    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:50      21   26.88    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:50      22   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:50      23   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:50      24   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:50      25   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:50      26   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:50      27   27.96    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:50      28   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:50      29   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:50      30   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:50      31   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08

08:22:50     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:51     all   27.92    0.00   18.82    1.59    0.00    0.00    0.00    0.00    0.00   51.67
08:22:51       0   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:51       1   25.53    0.00   21.28    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:22:51       2   26.80    0.00   20.62    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:51       3   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:51       4   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:51       5   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:51       6   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:51       7   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:51       8   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:51       9   27.84    0.00   20.62    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:22:51      10   30.21    0.00   17.71    3.12    0.00    0.00    0.00    0.00    0.00   48.96
08:22:51      11   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:51      12   29.90    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:22:51      13   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:51      14   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:51      15   25.51    0.00   22.45    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:22:51      16   27.55    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:51      17   30.93    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:51      18   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:51      19   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:51      20   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:51      21   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:51      22   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:22:51      23   26.60    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:51      24   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:51      25   26.53    0.00   21.43    1.02    0.00    0.00    0.00    0.00    0.00   51.02
08:22:51      26   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:51      27   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:51      28   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:51      29   27.37    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:51      30   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:51      31   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58

08:22:51     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:52     all   28.42    0.00   18.10    1.60    0.00    0.00    0.00    0.00    0.00   51.88
08:22:52       0   30.21    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:22:52       1   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:52       2   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:52       3   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:52       4   26.32    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:52       5   27.66    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:52       6   30.61    0.00   16.33    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:52       7   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:52       8   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:22:52       9   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:52      10   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:52      11   26.60    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:52      12   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:52      13   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:52      14   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:52      15   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:52      16   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:22:52      17   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:52      18   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:52      19   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:52      20   30.85    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:22:52      21   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:52      22   29.90    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:52      23   29.59    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:22:52      24   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:52      25   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:52      26   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:52      27   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:52      28   27.55    0.00   19.39    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:22:52      29   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:52      30   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:52      31   26.80    0.00   20.62    1.03    0.00    0.00    0.00    0.00    0.00   51.55

08:22:52     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:53     all   28.46    0.00   18.47    1.56    0.00    0.00    0.00    0.00    0.00   51.51
08:22:53       0   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:53       1   26.32    0.00   21.05    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:53       2   27.66    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:22:53       3   29.17    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:22:53       4   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:53       5   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:53       6   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:53       7   29.90    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:22:53       8   29.59    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:53       9   30.21    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:53      10   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:53      11   29.59    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   48.98
08:22:53      12   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:53      13   25.77    0.00   21.65    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:53      14   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:53      15   30.85    0.00   14.89    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:53      16   27.55    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:53      17   29.90    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:53      18   27.84    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:53      19   30.21    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:22:53      20   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:53      21   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:53      22   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:53      23   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:53      24   28.28    0.00   19.19    2.02    0.00    0.00    0.00    0.00    0.00   50.51
08:22:53      25   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:53      26   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:53      27   27.55    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:53      28   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:53      29   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:53      30   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:53      31   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63

08:22:53     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:54     all   28.71    0.00   18.04    1.50    0.00    0.00    0.00    0.00    0.00   51.75
08:22:54       0   29.59    0.00   19.39    1.02    0.00    0.00    0.00    0.00    0.00   50.00
08:22:54       1   29.90    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:54       2   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:54       3   29.59    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:54       4   29.90    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:54       5   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:54       6   29.79    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:22:54       7   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:54       8   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:54       9   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:22:54      10   28.12    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:22:54      11   27.17    0.00   17.39    1.09    0.00    0.00    0.00    0.00    0.00   54.35
08:22:54      12   29.03    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:54      13   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:54      14   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:54      15   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:54      16   28.42    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:22:54      17   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:54      18   30.53    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:54      19   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:54      20   30.53    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:22:54      21   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:54      22   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:22:54      23   29.90    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:54      24   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:54      25   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:54      26   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:54      27   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:54      28   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:54      29   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:22:54      30   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:54      31   29.90    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   51.55

08:22:54     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:55     all   27.82    0.00   18.29    1.58    0.00    0.00    0.00    0.00    0.00   52.31
08:22:55       0   25.26    0.00   21.05    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:55       1   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:55       2   27.66    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:22:55       3   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:55       4   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:55       5   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:55       6   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:55       7   26.88    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:55       8   29.03    0.00   16.13    2.15    0.00    0.00    0.00    0.00    0.00   52.69
08:22:55       9   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:55      10   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:55      11   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:55      12   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:55      13   30.11    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:22:55      14   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:55      15   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:55      16   26.60    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:55      17   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:55      18   28.12    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:22:55      19   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:55      20   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:55      21   27.96    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:22:55      22   25.53    0.00   20.21    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:55      23   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:55      24   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:55      25   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:55      26   26.60    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:55      27   27.96    0.00   17.20    2.15    0.00    0.00    0.00    0.00    0.00   52.69
08:22:55      28   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:55      29   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:55      30   26.60    0.00   21.28    1.06    0.00    0.00    0.00    0.00    0.00   51.06
08:22:55      31   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08

08:22:55     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:56     all   28.04    0.00   18.27    1.50    0.00    0.00    0.00    0.00    0.00   52.19
08:22:56       0   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:56       1   27.96    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:22:56       2   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:56       3   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:56       4   32.29    0.00   14.58    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:56       5   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:56       6   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:56       7   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:56       8   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:56       9   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:56      10   26.60    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:56      11   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:22:56      12   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:56      13   27.55    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:22:56      14   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:56      15   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:56      16   25.77    0.00   20.62    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:56      17   30.21    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:56      18   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:56      19   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:56      20   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:56      21   26.04    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   54.17
08:22:56      22   27.37    0.00   17.89    3.16    0.00    0.00    0.00    0.00    0.00   51.58
08:22:56      23   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:56      24   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:56      25   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:56      26   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:56      27   25.53    0.00   20.21    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:56      28   28.57    0.00   17.35    1.02    0.00    0.00    0.00    0.00    0.00   53.06
08:22:56      29   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:56      30   28.12    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:22:56      31   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58

08:22:56     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:57     all   27.89    0.00   18.14    1.67    0.00    0.00    0.00    0.00    0.00   52.30
08:22:57       0   26.04    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:57       1   26.60    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:57       2   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:57       3   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:57       4   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:57       5   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:57       6   27.66    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:22:57       7   26.60    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:57       8   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:57       9   26.80    0.00   20.62    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:57      10   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:57      11   28.42    0.00   17.89    0.00    0.00    0.00    0.00    0.00    0.00   53.68
08:22:57      12   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:57      13   29.90    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:57      14   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:57      15   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:57      16   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:57      17   27.37    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   54.74
08:22:57      18   27.17    0.00   17.39    1.09    0.00    0.00    0.00    0.00    0.00   54.35
08:22:57      19   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:57      20   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:57      21   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:57      22   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:57      23   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:57      24   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:57      25   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:57      26   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:22:57      27   27.08    0.00   18.75    3.12    0.00    0.00    0.00    0.00    0.00   51.04
08:22:57      28   26.80    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   52.58
08:22:57      29   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:22:57      30   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:57      31   27.96    0.00   16.13    2.15    0.00    0.00    0.00    0.00    0.00   53.76

08:22:57     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:58     all   28.73    0.00   17.97    1.53    0.00    0.00    0.00    0.00    0.00   51.76
08:22:58       0   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:58       1   26.32    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:58       2   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:58       3   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:58       4   30.30    0.00   18.18    2.02    0.00    0.00    0.00    0.00    0.00   49.49
08:22:58       5   30.21    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:58       6   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:58       7   29.59    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   51.02
08:22:58       8   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:22:58       9   29.03    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:22:58      10   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:58      11   29.47    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:58      12   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:58      13   27.66    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:22:58      14   27.96    0.00   18.28    2.15    0.00    0.00    0.00    0.00    0.00   51.61
08:22:58      15   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:58      16   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:58      17   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:58      18   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:58      19   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:58      20   27.96    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:22:58      21   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:58      22   29.59    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   51.02
08:22:58      23   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:58      24   28.12    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:22:58      25   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:58      26   30.21    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:58      27   28.12    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:22:58      28   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:58      29   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:22:58      30   30.21    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:58      31   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58

08:22:58     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:22:59     all   28.53    0.00   18.06    1.57    0.00    0.00    0.00    0.00    0.00   51.83
08:22:59       0   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:59       1   27.37    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:22:59       2   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:59       3   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:22:59       4   29.79    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:59       5   27.37    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:59       6   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:59       7   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:22:59       8   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:59       9   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:22:59      10   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:22:59      11   31.58    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:22:59      12   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:59      13   31.25    0.00   16.67    3.12    0.00    0.00    0.00    0.00    0.00   48.96
08:22:59      14   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:59      15   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:22:59      16   29.47    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   50.53
08:22:59      17   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:59      18   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:59      19   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:59      20   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:59      21   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:22:59      22   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:22:59      23   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:22:59      24   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:22:59      25   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:59      26   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:22:59      27   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:59      28   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:22:59      29   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:22:59      30   29.47    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:22:59      31   28.57    0.00   19.39    1.02    0.00    0.00    0.00    0.00    0.00   51.02

08:22:59     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:00     all   27.98    0.00   18.27    1.47    0.00    0.00    0.00    0.00    0.00   52.27
08:23:00       0   27.37    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:00       1   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:00       2   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:00       3   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:00       4   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:00       5   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:00       6   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:00       7   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:00       8   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:00       9   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:00      10   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:00      11   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:00      12   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:00      13   26.04    0.00   20.83    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:00      14   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:00      15   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:00      16   26.32    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:00      17   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:23:00      18   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:00      19   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:00      20   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:00      21   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:00      22   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:00      23   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:00      24   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:00      25   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:00      26   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:00      27   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:00      28   28.42    0.00   16.84    0.00    0.00    0.00    0.00    0.00    0.00   54.74
08:23:00      29   26.60    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:00      30   26.32    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:00      31   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58

08:23:00     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:01     all   28.79    0.00   18.09    1.59    0.00    0.00    0.00    0.00    0.00   51.52
08:23:01       0   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:01       1   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:01       2   29.90    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:01       3   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:23:01       4   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:01       5   30.61    0.00   16.33    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:23:01       6   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:01       7   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:01       8   30.93    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:23:01       9   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:01      10   27.84    0.00   21.65    3.09    0.00    0.00    0.00    0.00    0.00   47.42
08:23:01      11   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:01      12   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:01      13   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:01      14   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:01      15   29.17    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:01      16   28.57    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:23:01      17   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:01      18   29.90    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:01      19   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:01      20   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:01      21   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:01      22   29.90    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:01      23   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:01      24   27.55    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:23:01      25   26.60    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:01      26   30.61    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:01      27   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:01      28   29.79    0.00   14.89    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:23:01      29   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:23:01      30   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:01      31   28.28    0.00   18.18    2.02    0.00    0.00    0.00    0.00    0.00   51.52

08:23:01     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:02     all   28.52    0.00   18.29    1.60    0.00    0.00    0.00    0.00    0.00   51.60
08:23:02       0   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:02       1   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:02       2   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:02       3   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:02       4   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:02       5   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:02       6   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:02       7   30.93    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:02       8   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:23:02       9   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:02      10   31.58    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   50.53
08:23:02      11   28.12    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:02      12   28.12    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   48.96
08:23:02      13   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:02      14   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:02      15   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:02      16   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:02      17   29.90    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:02      18   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:02      19   26.04    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:23:02      20   30.21    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:02      21   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:02      22   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:02      23   26.04    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:02      24   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:23:02      25   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:02      26   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:02      27   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:02      28   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:23:02      29   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:02      30   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:02      31   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63

08:23:02     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:03     all   28.81    0.00   18.16    1.36    0.00    0.00    0.00    0.00    0.00   51.67
08:23:03       0   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:03       1   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:03       2   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:03       3   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:03       4   28.87    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:23:03       5   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:03       6   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:23:03       7   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:03       8   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:03       9   30.21    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:03      10   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:03      11   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:03      12   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:03      13   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:03      14   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:03      15   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:03      16   29.90    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:03      17   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:03      18   29.90    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:03      19   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:03      20   31.58    0.00   13.68    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:23:03      21   28.28    0.00   19.19    2.02    0.00    0.00    0.00    0.00    0.00   50.51
08:23:03      22   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:03      23   32.99    0.00   14.43    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:03      24   30.21    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:03      25   30.21    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:03      26   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:03      27   28.57    0.00   19.39    1.02    0.00    0.00    0.00    0.00    0.00   51.02
08:23:03      28   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:03      29   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:23:03      30   26.80    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:23:03      31   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68

08:23:03     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:04     all   28.60    0.00   17.85    1.70    0.00    0.00    0.00    0.00    0.00   51.85
08:23:04       0   31.96    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:04       1   27.66    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:04       2   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:04       3   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:04       4   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:04       5   31.63    0.00   16.33    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:04       6   28.26    0.00   17.39    1.09    0.00    0.00    0.00    0.00    0.00   53.26
08:23:04       7   27.55    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:23:04       8   30.53    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:04       9   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:04      10   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:04      11   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:04      12   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:04      13   31.25    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:04      14   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:04      15   29.79    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:04      16   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:04      17   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:04      18   26.88    0.00   18.28    2.15    0.00    0.00    0.00    0.00    0.00   52.69
08:23:04      19   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:23:04      20   29.17    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:04      21   28.12    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:04      22   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:04      23   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:04      24   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:04      25   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:04      26   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:04      27   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:04      28   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:04      29   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:04      30   29.47    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:04      31   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68

08:23:04     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:05     all   28.18    0.00   18.95    1.49    0.00    0.00    0.00    0.00    0.00   51.38
08:23:05       0   28.12    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:05       1   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:05       2   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:05       3   26.80    0.00   20.62    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:05       4   28.12    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:05       5   28.12    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:05       6   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:05       7   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:05       8   29.29    0.00   18.18    2.02    0.00    0.00    0.00    0.00    0.00   50.51
08:23:05       9   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:05      10   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:05      11   30.93    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:05      12   28.87    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:23:05      13   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:05      14   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:05      15   27.66    0.00   20.21    1.06    0.00    0.00    0.00    0.00    0.00   51.06
08:23:05      16   26.32    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:05      17   31.25    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:05      18   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:23:05      19   27.55    0.00   20.41    1.02    0.00    0.00    0.00    0.00    0.00   51.02
08:23:05      20   26.26    0.00   20.20    2.02    0.00    0.00    0.00    0.00    0.00   51.52
08:23:05      21   27.27    0.00   19.19    2.02    0.00    0.00    0.00    0.00    0.00   51.52
08:23:05      22   28.57    0.00   19.39    1.02    0.00    0.00    0.00    0.00    0.00   51.02
08:23:05      23   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:05      24   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:05      25   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:05      26   27.37    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:05      27   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:05      28   26.53    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:23:05      29   30.30    0.00   18.18    1.01    0.00    0.00    0.00    0.00    0.00   50.51
08:23:05      30   26.80    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:23:05      31   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58

08:23:05     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:06     all   28.51    0.00   17.94    1.60    0.00    0.00    0.00    0.00    0.00   51.96
08:23:06       0   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:06       1   31.63    0.00   16.33    3.06    0.00    0.00    0.00    0.00    0.00   48.98
08:23:06       2   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:06       3   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:06       4   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:06       5   30.93    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:06       6   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:06       7   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:06       8   29.03    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:06       9   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:06      10   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:06      11   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:06      12   27.55    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:23:06      13   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:06      14   30.21    0.00   16.67    0.00    0.00    0.00    0.00    0.00    0.00   53.12
08:23:06      15   27.84    0.00   18.56    3.09    0.00    0.00    0.00    0.00    0.00   50.52
08:23:06      16   25.26    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:06      17   25.26    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:06      18   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:23:06      19   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:06      20   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:06      21   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:06      22   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:06      23   29.90    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:06      24   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:23:06      25   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:06      26   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:06      27   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:06      28   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:06      29   29.90    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:06      30   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:06      31   27.84    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   53.61

08:23:06     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:07     all   28.23    0.00   18.14    1.47    0.00    0.00    0.00    0.00    0.00   52.16
08:23:07       0   25.00    0.00   21.88    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:07       1   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:07       2   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:07       3   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:07       4   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:07       5   30.53    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:07       6   29.79    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:07       7   29.17    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:07       8   26.80    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:23:07       9   29.17    0.00   18.75    3.12    0.00    0.00    0.00    0.00    0.00   48.96
08:23:07      10   30.53    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:07      11   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:07      12   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:07      13   29.79    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:07      14   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:07      15   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:07      16   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:07      17   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:07      18   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:07      19   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:07      20   29.17    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:07      21   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:23:07      22   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:07      23   26.80    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:23:07      24   26.60    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:23:07      25   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:07      26   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:07      27   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:07      28   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:23:07      29   26.88    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:23:07      30   29.47    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:07      31   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63

08:23:07     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:08     all   28.46    0.00   18.44    1.72    0.00    0.00    0.00    0.00    0.00   51.38
08:23:08       0   28.12    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:08       1   28.87    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:08       2   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:08       3   29.47    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   50.53
08:23:08       4   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:08       5   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:23:08       6   30.53    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:08       7   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:08       8   28.72    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:08       9   29.59    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:08      10   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:08      11   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:08      12   28.42    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:08      13   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:08      14   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:08      15   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:08      16   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:08      17   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:08      18   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:08      19   27.55    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:23:08      20   26.32    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:23:08      21   29.90    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:23:08      22   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:08      23   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:08      24   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:08      25   26.80    0.00   20.62    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:08      26   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:08      27   26.53    0.00   20.41    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:23:08      28   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:08      29   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:08      30   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:08      31   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08

08:23:08     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:09     all   28.18    0.00   18.33    1.47    0.00    0.00    0.00    0.00    0.00   52.01
08:23:09       0   29.79    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:09       1   26.88    0.00   19.35    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:09       2   26.04    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:09       3   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:23:09       4   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:09       5   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:09       6   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:09       7   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:09       8   25.77    0.00   20.62    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:09       9   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:09      10   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:09      11   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:09      12   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:09      13   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:09      14   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:09      15   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:09      16   25.53    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   53.19
08:23:09      17   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:23:09      18   30.21    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:09      19   29.79    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:09      20   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:09      21   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:09      22   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:09      23   29.79    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:09      24   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:09      25   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:09      26   26.32    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:09      27   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:23:09      28   29.79    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:09      29   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:09      30   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:09      31   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55

08:23:09     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:10     all   28.56    0.00   18.10    1.60    0.00    0.00    0.00    0.00    0.00   51.74
08:23:10       0   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:10       1   27.27    0.00   20.20    2.02    0.00    0.00    0.00    0.00    0.00   50.51
08:23:10       2   30.21    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:10       3   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:10       4   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:10       5   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:10       6   30.61    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   50.00
08:23:10       7   29.90    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:10       8   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:10       9   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:10      10   29.03    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:10      11   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:10      12   29.90    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:10      13   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:10      14   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:23:10      15   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:23:10      16   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:10      17   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:10      18   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:10      19   29.47    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:10      20   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:10      21   29.79    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:10      22   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:10      23   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:10      24   28.87    0.00   17.53    3.09    0.00    0.00    0.00    0.00    0.00   50.52
08:23:10      25   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:10      26   26.88    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:23:10      27   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:10      28   30.61    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:10      29   30.93    0.00   15.46    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:10      30   26.04    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:23:10      31   29.17    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   53.12

08:23:10     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:11     all   28.15    0.00   18.89    1.56    0.00    0.00    0.00    0.00    0.00   51.40
08:23:11       0   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:11       1   31.96    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:23:11       2   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:11       3   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:11       4   30.21    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:11       5   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:11       6   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:11       7   28.12    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:11       8   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:11       9   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:11      10   27.08    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:11      11   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:11      12   30.21    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:11      13   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:11      14   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:11      15   25.77    0.00   21.65    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:11      16   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:11      17   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:11      18   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:11      19   27.84    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:23:11      20   26.80    0.00   20.62    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:11      21   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:11      22   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:11      23   26.80    0.00   20.62    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:11      24   27.08    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:11      25   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:11      26   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:11      27   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:11      28   26.80    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:23:11      29   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:23:11      30   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:11      31   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63

08:23:11     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:12     all   28.27    0.00   18.17    1.57    0.00    0.00    0.00    0.00    0.00   51.99
08:23:12       0   25.53    0.00   20.21    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:12       1   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:12       2   29.90    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:12       3   27.96    0.00   17.20    2.15    0.00    0.00    0.00    0.00    0.00   52.69
08:23:12       4   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:12       5   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:12       6   28.87    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   52.58
08:23:12       7   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:12       8   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:12       9   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:12      10   29.59    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:12      11   28.72    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:12      12   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:12      13   30.53    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:12      14   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:12      15   27.96    0.00   17.20    0.00    0.00    0.00    0.00    0.00    0.00   54.84
08:23:12      16   29.79    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:12      17   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:23:12      18   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:12      19   26.32    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:12      20   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:12      21   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:12      22   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:12      23   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:23:12      24   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:12      25   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:12      26   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:12      27   29.59    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:12      28   26.04    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:12      29   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:12      30   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:12      31   27.08    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   54.17

08:23:12     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:13     all   27.86    0.00   18.53    1.58    0.00    0.00    0.00    0.00    0.00   52.04
08:23:13       0   27.66    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:13       1   27.96    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:13       2   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:13       3   29.17    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:13       4   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:13       5   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:13       6   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:13       7   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:13       8   26.88    0.00   19.35    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:13       9   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:13      10   26.88    0.00   18.28    2.15    0.00    0.00    0.00    0.00    0.00   52.69
08:23:13      11   30.85    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:13      12   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:13      13   26.04    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:13      14   27.55    0.00   20.41    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:13      15   27.17    0.00   16.30    2.17    0.00    0.00    0.00    0.00    0.00   54.35
08:23:13      16   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:13      17   28.72    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:13      18   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:13      19   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:13      20   26.60    0.00   20.21    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:13      21   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:13      22   26.80    0.00   20.62    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:13      23   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:13      24   25.25    0.00   21.21    2.02    0.00    0.00    0.00    0.00    0.00   51.52
08:23:13      25   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:13      26   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:13      27   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:13      28   28.42    0.00   17.89    0.00    0.00    0.00    0.00    0.00    0.00   53.68
08:23:13      29   28.26    0.00   17.39    1.09    0.00    0.00    0.00    0.00    0.00   53.26
08:23:13      30   29.47    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:23:13      31   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55

08:23:13     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:14     all   28.13    0.00   18.33    1.51    0.00    0.00    0.00    0.00    0.00   52.02
08:23:14       0   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:14       1   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:14       2   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:14       3   26.88    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:23:14       4   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:14       5   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:14       6   28.72    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:14       7   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:14       8   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:14       9   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:14      10   29.47    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   50.53
08:23:14      11   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:14      12   26.04    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:14      13   29.03    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:14      14   26.60    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:14      15   27.96    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:14      16   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:14      17   27.96    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:23:14      18   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:14      19   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:14      20   28.12    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:23:14      21   27.37    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:14      22   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:14      23   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:14      24   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:14      25   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:14      26   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:14      27   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:14      28   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:23:14      29   26.04    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:14      30   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:14      31   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13

08:23:14     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:15     all   28.30    0.00   18.58    1.60    0.00    0.00    0.00    0.00    0.00   51.52
08:23:15       0   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:15       1   27.37    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:15       2   28.12    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   48.96
08:23:15       3   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:15       4   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:15       5   29.59    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:15       6   29.17    0.00   18.75    0.00    0.00    0.00    0.00    0.00    0.00   52.08
08:23:15       7   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:15       8   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:15       9   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:15      10   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:15      11   28.12    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:15      12   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:15      13   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:15      14   29.79    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:15      15   28.57    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:15      16   29.79    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:15      17   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:15      18   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:15      19   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:15      20   27.96    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:15      21   28.87    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:23:15      22   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:15      23   29.79    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:15      24   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:15      25   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:15      26   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:15      27   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:15      28   25.00    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:15      29   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:23:15      30   29.79    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:15      31   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63

08:23:15     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:16     all   36.84    0.00   16.01    1.30    0.00    0.00    0.00    0.00    0.00   45.85
08:23:16       0   35.11    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   45.74
08:23:16       1   35.79    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   46.32
08:23:16       2   35.42    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   45.83
08:23:16       3   37.89    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   45.26
08:23:16       4   36.84    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   46.32
08:23:16       5   36.73    0.00   16.33    1.02    0.00    0.00    0.00    0.00    0.00   45.92
08:23:16       6   37.11    0.00   15.46    2.06    0.00    0.00    0.00    0.00    0.00   45.36
08:23:16       7   36.46    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   45.83
08:23:16       8   37.11    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   45.36
08:23:16       9   37.11    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   44.33
08:23:16      10   37.50    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   44.79
08:23:16      11   36.08    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   45.36
08:23:16      12   35.42    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   45.83
08:23:16      13   41.67    0.00   14.58    1.04    0.00    0.00    0.00    0.00    0.00   42.71
08:23:16      14   37.50    0.00   14.58    1.04    0.00    0.00    0.00    0.00    0.00   46.88
08:23:16      15   37.89    0.00   14.74    2.11    0.00    0.00    0.00    0.00    0.00   45.26
08:23:16      16   35.42    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   46.88
08:23:16      17   36.08    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   45.36
08:23:16      18   35.11    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   47.87
08:23:16      19   36.46    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   45.83
08:23:16      20   35.42    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   46.88
08:23:16      21   36.84    0.00   14.74    2.11    0.00    0.00    0.00    0.00    0.00   46.32
08:23:16      22   38.38    0.00   15.15    1.01    0.00    0.00    0.00    0.00    0.00   45.45
08:23:16      23   37.11    0.00   14.43    2.06    0.00    0.00    0.00    0.00    0.00   46.39
08:23:16      24   35.79    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   46.32
08:23:16      25   34.38    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   45.83
08:23:16      26   38.54    0.00   13.54    1.04    0.00    0.00    0.00    0.00    0.00   46.88
08:23:16      27   37.50    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   45.83
08:23:16      28   38.14    0.00   15.46    1.03    0.00    0.00    0.00    0.00    0.00   45.36
08:23:16      29   36.84    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   46.32
08:23:16      30   36.46    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   46.88
08:23:16      31   38.54    0.00   14.58    1.04    0.00    0.00    0.00    0.00    0.00   45.83

08:23:16     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:17     all   28.59    0.00   17.85    1.61    0.00    0.00    0.00    0.00    0.00   51.94
08:23:17       0   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:17       1   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:17       2   28.72    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:17       3   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:17       4   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:17       5   27.96    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:17       6   29.79    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:17       7   28.42    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:17       8   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:17       9   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:17      10   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:17      11   29.79    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:17      12   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:17      13   30.85    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:17      14   30.21    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:17      15   26.32    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:17      16   29.79    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:17      17   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:17      18   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:17      19   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:23:17      20   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:17      21   29.79    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:17      22   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:17      23   29.03    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:17      24   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:17      25   31.91    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   51.06
08:23:17      26   26.32    0.00   21.05    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:17      27   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:17      28   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:17      29   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:17      30   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:17      31   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19

08:23:17     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:18     all   36.71    0.00   16.52    1.31    0.00    0.00    0.00    0.00    0.00   45.45
08:23:18       0   36.84    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   46.32
08:23:18       1   33.68    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   45.26
08:23:18       2   38.95    0.00   13.68    1.05    0.00    0.00    0.00    0.00    0.00   46.32
08:23:18       3   36.08    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   44.33
08:23:18       4   38.54    0.00   15.62    1.04    0.00    0.00    0.00    0.00    0.00   44.79
08:23:18       5   39.18    0.00   14.43    2.06    0.00    0.00    0.00    0.00    0.00   44.33
08:23:18       6   37.89    0.00   14.74    1.05    0.00    0.00    0.00    0.00    0.00   46.32
08:23:18       7   38.30    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   44.68
08:23:18       8   37.11    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   44.33
08:23:18       9   37.23    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   45.74
08:23:18      10   37.23    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   43.62
08:23:18      11   36.46    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   44.79
08:23:18      12   39.36    0.00   13.83    1.06    0.00    0.00    0.00    0.00    0.00   45.74
08:23:18      13   35.79    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   46.32
08:23:18      14   35.11    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   46.81
08:23:18      15   35.11    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   45.74
08:23:18      16   35.42    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   44.79
08:23:18      17   36.73    0.00   17.35    1.02    0.00    0.00    0.00    0.00    0.00   44.90
08:23:18      18   38.95    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   44.21
08:23:18      19   36.84    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   45.26
08:23:18      20   34.38    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   45.83
08:23:18      21   36.46    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   44.79
08:23:18      22   34.38    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   45.83
08:23:18      23   37.11    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   44.33
08:23:18      24   38.30    0.00   14.89    1.06    0.00    0.00    0.00    0.00    0.00   45.74
08:23:18      25   36.73    0.00   16.33    2.04    0.00    0.00    0.00    0.00    0.00   44.90
08:23:18      26   36.84    0.00   14.74    1.05    0.00    0.00    0.00    0.00    0.00   47.37
08:23:18      27   34.74    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   45.26
08:23:18      28   35.11    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   47.87
08:23:18      29   37.11    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   45.36
08:23:18      30   36.08    0.00   16.49    1.03    0.00    0.00    0.00    0.00    0.00   46.39
08:23:18      31   36.84    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   46.32

08:23:18     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:19     all   28.73    0.00   18.41    1.51    0.00    0.00    0.00    0.00    0.00   51.35
08:23:19       0   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:19       1   27.66    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:19       2   27.66    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:19       3   28.72    0.00   18.09    0.00    0.00    0.00    0.00    0.00    0.00   53.19
08:23:19       4   31.58    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   49.47
08:23:19       5   25.26    0.00   22.11    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:19       6   29.90    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:19       7   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:19       8   27.96    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:19       9   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:19      10   30.61    0.00   16.33    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:23:19      11   29.47    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   50.53
08:23:19      12   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:19      13   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:19      14   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:23:19      15   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:19      16   27.66    0.00   19.15    0.00    0.00    0.00    0.00    0.00    0.00   53.19
08:23:19      17   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:19      18   29.90    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:19      19   29.79    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   51.06
08:23:19      20   28.42    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   49.47
08:23:19      21   28.72    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:19      22   26.60    0.00   20.21    3.19    0.00    0.00    0.00    0.00    0.00   50.00
08:23:19      23   29.79    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   50.00
08:23:19      24   30.21    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:19      25   29.17    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:19      26   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:19      27   31.25    0.00   15.62    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:19      28   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:19      29   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:19      30   26.60    0.00   21.28    1.06    0.00    0.00    0.00    0.00    0.00   51.06
08:23:19      31   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08

08:23:19     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:20     all   28.73    0.00   18.54    2.14    0.00    0.00    0.00    0.00    0.00   50.59
08:23:20       0   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:20       1   27.37    0.00   21.05    3.16    0.00    0.00    0.00    0.00    0.00   48.42
08:23:20       2   27.37    0.00   21.05    2.11    0.00    0.00    0.00    0.00    0.00   49.47
08:23:20       3   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:20       4   29.79    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   50.00
08:23:20       5   29.79    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   50.00
08:23:20       6   29.47    0.00   18.95    4.21    0.00    0.00    0.00    0.00    0.00   47.37
08:23:20       7   31.58    0.00   17.89    3.16    0.00    0.00    0.00    0.00    0.00   47.37
08:23:20       8   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:20       9   29.47    0.00   18.95    6.32    0.00    0.00    0.00    0.00    0.00   45.26
08:23:20      10   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:20      11   27.37    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:20      12   30.21    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:20      13   27.66    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:20      14   29.03    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:20      15   30.21    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:20      16   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:20      17   29.03    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:20      18   29.17    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:20      19   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:20      20   30.21    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:20      21   29.17    0.00   17.71    3.12    0.00    0.00    0.00    0.00    0.00   50.00
08:23:20      22   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:20      23   26.04    0.00   20.83    3.12    0.00    0.00    0.00    0.00    0.00   50.00
08:23:20      24   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:20      25   29.79    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:20      26   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:20      27   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:20      28   29.79    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:20      29   27.66    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:20      30   25.53    0.00   21.28    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:20      31   29.17    0.00   17.71    3.12    0.00    0.00    0.00    0.00    0.00   50.00

08:23:20     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:21     all   27.98    0.00   17.94    2.48    0.00    0.00    0.00    0.00    0.00   51.60
08:23:21       0   27.96    0.00   18.28    3.23    0.00    0.00    0.00    0.00    0.00   50.54
08:23:21       1   30.93    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   48.45
08:23:21       2   28.12    0.00   18.75    3.12    0.00    0.00    0.00    0.00    0.00   50.00
08:23:21       3   28.12    0.00   18.75    4.17    0.00    0.00    0.00    0.00    0.00   48.96
08:23:21       4   27.66    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:21       5   27.66    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:21       6   30.21    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:21       7   29.03    0.00   16.13    3.23    0.00    0.00    0.00    0.00    0.00   51.61
08:23:21       8   27.66    0.00   18.09    6.38    0.00    0.00    0.00    0.00    0.00   47.87
08:23:21       9   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:21      10   27.17    0.00   18.48    4.35    0.00    0.00    0.00    0.00    0.00   50.00
08:23:21      11   27.37    0.00   18.95    3.16    0.00    0.00    0.00    0.00    0.00   50.53
08:23:21      12   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:21      13   30.11    0.00   13.98    1.08    0.00    0.00    0.00    0.00    0.00   54.84
08:23:21      14   26.32    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:21      15   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:23:21      16   26.60    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:21      17   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:21      18   27.96    0.00   17.20    2.15    0.00    0.00    0.00    0.00    0.00   52.69
08:23:21      19   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:21      20   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:21      21   28.26    0.00   16.30    1.09    0.00    0.00    0.00    0.00    0.00   54.35
08:23:21      22   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:21      23   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:21      24   26.60    0.00   19.15    3.19    0.00    0.00    0.00    0.00    0.00   51.06
08:23:21      25   25.53    0.00   19.15    3.19    0.00    0.00    0.00    0.00    0.00   52.13
08:23:21      26   27.37    0.00   17.89    4.21    0.00    0.00    0.00    0.00    0.00   50.53
08:23:21      27   29.47    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:21      28   26.53    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   52.04
08:23:21      29   30.53    0.00   14.74    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:23:21      30   25.26    0.00   20.00    3.16    0.00    0.00    0.00    0.00    0.00   51.58
08:23:21      31   26.60    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   53.19

08:23:21     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:22     all   28.56    0.00   18.89    2.19    0.00    0.00    0.00    0.00    0.00   50.36
08:23:22       0   28.12    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:22       1   28.42    0.00   20.00    3.16    0.00    0.00    0.00    0.00    0.00   48.42
08:23:22       2   28.72    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   50.00
08:23:22       3   30.11    0.00   16.13    2.15    0.00    0.00    0.00    0.00    0.00   51.61
08:23:22       4   29.90    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:22       5   28.12    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:22       6   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:22       7   27.37    0.00   21.05    2.11    0.00    0.00    0.00    0.00    0.00   49.47
08:23:22       8   29.17    0.00   20.83    6.25    0.00    0.00    0.00    0.00    0.00   43.75
08:23:22       9   27.08    0.00   18.75    3.12    0.00    0.00    0.00    0.00    0.00   51.04
08:23:22      10   30.93    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:22      11   27.84    0.00   20.62    5.15    0.00    0.00    0.00    0.00    0.00   46.39
08:23:22      12   27.84    0.00   20.62    3.09    0.00    0.00    0.00    0.00    0.00   48.45
08:23:22      13   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:22      14   30.21    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:22      15   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:22      16   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:22      17   28.87    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:22      18   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:22      19   30.21    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:22      20   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:22      21   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:22      22   25.53    0.00   20.21    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:22      23   29.79    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:22      24   30.21    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   48.96
08:23:22      25   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:22      26   27.66    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:22      27   27.84    0.00   20.62    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:23:22      28   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:23:22      29   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:22      30   29.90    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:22      31   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19

08:23:22     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:23     all   28.82    0.00   18.35    2.07    0.00    0.00    0.00    0.00    0.00   50.76
08:23:23       0   28.12    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:23       1   29.47    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   50.53
08:23:23       2   29.17    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:23       3   28.42    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:23       4   30.53    0.00   16.84    3.16    0.00    0.00    0.00    0.00    0.00   49.47
08:23:23       5   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:23       6   29.79    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:23       7   28.42    0.00   16.84    4.21    0.00    0.00    0.00    0.00    0.00   50.53
08:23:23       8   29.90    0.00   18.56    3.09    0.00    0.00    0.00    0.00    0.00   48.45
08:23:23       9   29.35    0.00   17.39    1.09    0.00    0.00    0.00    0.00    0.00   52.17
08:23:23      10   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:23      11   27.96    0.00   19.35    2.15    0.00    0.00    0.00    0.00    0.00   50.54
08:23:23      12   29.17    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   48.96
08:23:23      13   30.21    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:23      14   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:23      15   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:23      16   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:23      17   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:23      18   27.96    0.00   19.35    1.08    0.00    0.00    0.00    0.00    0.00   51.61
08:23:23      19   29.17    0.00   18.75    3.12    0.00    0.00    0.00    0.00    0.00   48.96
08:23:23      20   28.42    0.00   18.95    3.16    0.00    0.00    0.00    0.00    0.00   49.47
08:23:23      21   30.21    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:23      22   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:23      23   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:23      24   28.42    0.00   18.95    5.26    0.00    0.00    0.00    0.00    0.00   47.37
08:23:23      25   28.12    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:23      26   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:23      27   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:23      28   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:23      29   28.12    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:23:23      30   28.72    0.00   17.02    4.26    0.00    0.00    0.00    0.00    0.00   50.00
08:23:23      31   26.32    0.00   20.00    3.16    0.00    0.00    0.00    0.00    0.00   50.53

08:23:23     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:24     all   29.00    0.00   18.21    2.26    0.00    0.00    0.00    0.00    0.00   50.52
08:23:24       0   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:24       1   29.90    0.00   17.53    3.09    0.00    0.00    0.00    0.00    0.00   49.48
08:23:24       2   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:24       3   27.08    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:24       4   30.53    0.00   17.89    4.21    0.00    0.00    0.00    0.00    0.00   47.37
08:23:24       5   30.85    0.00   17.02    3.19    0.00    0.00    0.00    0.00    0.00   48.94
08:23:24       6   32.99    0.00   14.43    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:24       7   27.96    0.00   19.35    2.15    0.00    0.00    0.00    0.00    0.00   50.54
08:23:24       8   27.66    0.00   20.21    3.19    0.00    0.00    0.00    0.00    0.00   48.94
08:23:24       9   29.79    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:24      10   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:24      11   29.47    0.00   17.89    3.16    0.00    0.00    0.00    0.00    0.00   49.47
08:23:24      12   28.42    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:24      13   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:24      14   30.21    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:24      15   27.66    0.00   20.21    2.13    0.00    0.00    0.00    0.00    0.00   50.00
08:23:24      16   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:24      17   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:24      18   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:24      19   31.58    0.00   17.89    4.21    0.00    0.00    0.00    0.00    0.00   46.32
08:23:24      20   28.72    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:24      21   27.84    0.00   19.59    3.09    0.00    0.00    0.00    0.00    0.00   49.48
08:23:24      22   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:24      23   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:24      24   31.91    0.00   14.89    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:24      25   28.12    0.00   18.75    3.12    0.00    0.00    0.00    0.00    0.00   50.00
08:23:24      26   28.72    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:24      27   27.37    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:24      28   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:24      29   30.53    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:24      30   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:24      31   28.42    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   53.68

08:23:24     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:25     all   28.66    0.00   19.24    2.03    0.00    0.00    0.00    0.00    0.00   50.07
08:23:25       0   27.37    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:25       1   27.37    0.00   21.05    2.11    0.00    0.00    0.00    0.00    0.00   49.47
08:23:25       2   28.42    0.00   20.00    0.00    0.00    0.00    0.00    0.00    0.00   51.58
08:23:25       3   28.12    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   48.96
08:23:25       4   30.21    0.00   18.75    3.12    0.00    0.00    0.00    0.00    0.00   47.92
08:23:25       5   29.17    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   48.96
08:23:25       6   29.03    0.00   19.35    1.08    0.00    0.00    0.00    0.00    0.00   50.54
08:23:25       7   28.42    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   49.47
08:23:25       8   29.47    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   49.47
08:23:25       9   26.60    0.00   20.21    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:25      10   27.66    0.00   20.21    1.06    0.00    0.00    0.00    0.00    0.00   51.06
08:23:25      11   27.37    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:25      12   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:25      13   27.96    0.00   19.35    2.15    0.00    0.00    0.00    0.00    0.00   50.54
08:23:25      14   30.93    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:25      15   29.90    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:25      16   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:25      17   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:25      18   28.87    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:25      19   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:25      20   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:25      21   30.53    0.00   17.89    3.16    0.00    0.00    0.00    0.00    0.00   48.42
08:23:25      22   28.42    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:25      23   30.93    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   48.45
08:23:25      24   28.12    0.00   20.83    5.21    0.00    0.00    0.00    0.00    0.00   45.83
08:23:25      25   28.12    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:25      26   28.87    0.00   19.59    3.09    0.00    0.00    0.00    0.00    0.00   48.45
08:23:25      27   28.12    0.00   18.75    5.21    0.00    0.00    0.00    0.00    0.00   47.92
08:23:25      28   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:25      29   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:25      30   27.08    0.00   20.83    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:25      31   29.90    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   51.55

08:23:25     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:26     all   29.19    0.00   18.47    2.19    0.00    0.00    0.00    0.00    0.00   50.15
08:23:26       0   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:26       1   30.21    0.00   20.83    7.29    0.00    0.00    0.00    0.00    0.00   41.67
08:23:26       2   29.17    0.00   18.75    3.12    0.00    0.00    0.00    0.00    0.00   48.96
08:23:26       3   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:26       4   30.61    0.00   18.37    1.02    0.00    0.00    0.00    0.00    0.00   50.00
08:23:26       5   31.58    0.00   15.79    3.16    0.00    0.00    0.00    0.00    0.00   49.47
08:23:26       6   30.93    0.00   16.49    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:26       7   30.53    0.00   17.89    3.16    0.00    0.00    0.00    0.00    0.00   48.42
08:23:26       8   31.25    0.00   17.71    3.12    0.00    0.00    0.00    0.00    0.00   47.92
08:23:26       9   28.12    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:26      10   29.90    0.00   18.56    6.19    0.00    0.00    0.00    0.00    0.00   45.36
08:23:26      11   28.42    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:26      12   29.79    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   48.94
08:23:26      13   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:26      14   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:26      15   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:26      16   27.66    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:26      17   30.21    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:26      18   30.53    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:26      19   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:26      20   29.03    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   51.61
08:23:26      21   26.04    0.00   21.88    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:26      22   30.61    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   47.96
08:23:26      23   27.84    0.00   19.59    4.12    0.00    0.00    0.00    0.00    0.00   48.45
08:23:26      24   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:26      25   28.72    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:26      26   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:26      27   29.79    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:26      28   28.12    0.00   19.79    3.12    0.00    0.00    0.00    0.00    0.00   48.96
08:23:26      29   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:26      30   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:26      31   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08

08:23:26     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:27     all   28.86    0.00   18.13    2.11    0.00    0.00    0.00    0.00    0.00   50.90
08:23:27       0   26.80    0.00   20.62    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:27       1   30.85    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   51.06
08:23:27       2   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:27       3   28.72    0.00   19.15    3.19    0.00    0.00    0.00    0.00    0.00   48.94
08:23:27       4   28.42    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:27       5   29.03    0.00   18.28    3.23    0.00    0.00    0.00    0.00    0.00   49.46
08:23:27       6   30.11    0.00   17.20    2.15    0.00    0.00    0.00    0.00    0.00   50.54
08:23:27       7   29.79    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:27       8   29.47    0.00   17.89    4.21    0.00    0.00    0.00    0.00    0.00   48.42
08:23:27       9   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:27      10   30.21    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   47.92
08:23:27      11   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:27      12   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:27      13   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:27      14   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:27      15   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:27      16   30.53    0.00   16.84    3.16    0.00    0.00    0.00    0.00    0.00   49.47
08:23:27      17   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:27      18   27.66    0.00   19.15    0.00    0.00    0.00    0.00    0.00    0.00   53.19
08:23:27      19   30.21    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:27      20   28.42    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:27      21   29.47    0.00   17.89    3.16    0.00    0.00    0.00    0.00    0.00   49.47
08:23:27      22   29.03    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:27      23   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:27      24   27.66    0.00   19.15    3.19    0.00    0.00    0.00    0.00    0.00   50.00
08:23:27      25   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:27      26   30.85    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   50.00
08:23:27      27   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:27      28   30.61    0.00   16.33    3.06    0.00    0.00    0.00    0.00    0.00   50.00
08:23:27      29   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:27      30   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:27      31   28.72    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   51.06

08:23:27     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:28     all   29.23    0.00   18.89    2.34    0.00    0.00    0.00    0.00    0.00   49.54
08:23:28       0   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:28       1   31.25    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:28       2   28.87    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:28       3   27.55    0.00   21.43    2.04    0.00    0.00    0.00    0.00    0.00   48.98
08:23:28       4   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:28       5   29.59    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   48.98
08:23:28       6   30.93    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   48.45
08:23:28       7   29.90    0.00   18.56    4.12    0.00    0.00    0.00    0.00    0.00   47.42
08:23:28       8   28.12    0.00   20.83    6.25    0.00    0.00    0.00    0.00    0.00   44.79
08:23:28       9   28.42    0.00   18.95    3.16    0.00    0.00    0.00    0.00    0.00   49.47
08:23:28      10   30.53    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:28      11   29.90    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   48.45
08:23:28      12   29.17    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   48.96
08:23:28      13   28.87    0.00   20.62    2.06    0.00    0.00    0.00    0.00    0.00   48.45
08:23:28      14   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:28      15   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:28      16   28.87    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:28      17   31.91    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   48.94
08:23:28      18   27.27    0.00   20.20    2.02    0.00    0.00    0.00    0.00    0.00   50.51
08:23:28      19   30.93    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:28      20   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:28      21   30.21    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:28      22   30.93    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   48.45
08:23:28      23   29.47    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   50.53
08:23:28      24   28.12    0.00   20.83    6.25    0.00    0.00    0.00    0.00    0.00   44.79
08:23:28      25   27.66    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:28      26   28.57    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:28      27   27.96    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:28      28   29.90    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:28      29   30.21    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   48.96
08:23:28      30   28.12    0.00   19.79    3.12    0.00    0.00    0.00    0.00    0.00   48.96
08:23:28      31   28.42    0.00   17.89    3.16    0.00    0.00    0.00    0.00    0.00   50.53

08:23:28     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:29     all   27.81    0.00   18.99    2.28    0.00    0.00    0.00    0.00    0.00   50.92
08:23:29       0   29.03    0.00   18.28    2.15    0.00    0.00    0.00    0.00    0.00   50.54
08:23:29       1   27.96    0.00   18.28    2.15    0.00    0.00    0.00    0.00    0.00   51.61
08:23:29       2   31.18    0.00   16.13    2.15    0.00    0.00    0.00    0.00    0.00   50.54
08:23:29       3   29.47    0.00   17.89    3.16    0.00    0.00    0.00    0.00    0.00   49.47
08:23:29       4   27.66    0.00   18.09    4.26    0.00    0.00    0.00    0.00    0.00   50.00
08:23:29       5   26.88    0.00   19.35    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:29       6   29.90    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   48.45
08:23:29       7   27.37    0.00   21.05    3.16    0.00    0.00    0.00    0.00    0.00   48.42
08:23:29       8   28.72    0.00   19.15    5.32    0.00    0.00    0.00    0.00    0.00   46.81
08:23:29       9   26.60    0.00   20.21    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:29      10   28.12    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:29      11   26.88    0.00   19.35    3.23    0.00    0.00    0.00    0.00    0.00   50.54
08:23:29      12   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:29      13   26.60    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:29      14   27.96    0.00   17.20    0.00    0.00    0.00    0.00    0.00    0.00   54.84
08:23:29      15   28.72    0.00   18.09    4.26    0.00    0.00    0.00    0.00    0.00   48.94
08:23:29      16   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:29      17   28.12    0.00   18.75    3.12    0.00    0.00    0.00    0.00    0.00   50.00
08:23:29      18   28.12    0.00   18.75    5.21    0.00    0.00    0.00    0.00    0.00   47.92
08:23:29      19   28.12    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:29      20   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:29      21   26.32    0.00   21.05    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:29      22   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:29      23   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:29      24   27.96    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:29      25   26.60    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:29      26   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:29      27   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:29      28   26.88    0.00   19.35    2.15    0.00    0.00    0.00    0.00    0.00   51.61
08:23:29      29   25.26    0.00   21.05    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:29      30   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:29      31   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58

08:23:29     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:30     all   28.92    0.00   18.78    2.07    0.00    0.00    0.00    0.00    0.00   50.23
08:23:30       0   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:30       1   28.42    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   50.53
08:23:30       2   28.12    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   48.96
08:23:30       3   31.96    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   48.45
08:23:30       4   28.72    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   51.06
08:23:30       5   29.17    0.00   18.75    3.12    0.00    0.00    0.00    0.00    0.00   48.96
08:23:30       6   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:30       7   27.37    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:30       8   28.42    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:30       9   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:30      10   30.11    0.00   18.28    3.23    0.00    0.00    0.00    0.00    0.00   48.39
08:23:30      11   29.90    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:30      12   27.96    0.00   19.35    2.15    0.00    0.00    0.00    0.00    0.00   50.54
08:23:30      13   28.12    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:30      14   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:30      15   29.17    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:30      16   30.21    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:30      17   27.96    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:23:30      18   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:30      19   30.21    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:30      20   28.72    0.00   19.15    4.26    0.00    0.00    0.00    0.00    0.00   47.87
08:23:30      21   29.79    0.00   18.09    3.19    0.00    0.00    0.00    0.00    0.00   48.94
08:23:30      22   31.25    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   48.96
08:23:30      23   28.42    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   49.47
08:23:30      24   27.08    0.00   20.83    3.12    0.00    0.00    0.00    0.00    0.00   48.96
08:23:30      25   30.53    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   50.53
08:23:30      26   29.47    0.00   17.89    3.16    0.00    0.00    0.00    0.00    0.00   49.47
08:23:30      27   26.04    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:30      28   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:30      29   29.03    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:23:30      30   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:30      31   28.42    0.00   18.95    4.21    0.00    0.00    0.00    0.00    0.00   48.42

08:23:30     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:31     all   28.63    0.00   18.57    2.21    0.00    0.00    0.00    0.00    0.00   50.59
08:23:31       0   27.66    0.00   20.21    2.13    0.00    0.00    0.00    0.00    0.00   50.00
08:23:31       1   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:31       2   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:31       3   30.53    0.00   16.84    3.16    0.00    0.00    0.00    0.00    0.00   49.47
08:23:31       4   30.21    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:31       5   27.66    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:31       6   29.35    0.00   17.39    1.09    0.00    0.00    0.00    0.00    0.00   52.17
08:23:31       7   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:31       8   29.35    0.00   17.39    0.00    0.00    0.00    0.00    0.00    0.00   53.26
08:23:31       9   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:31      10   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:31      11   27.66    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:31      12   29.03    0.00   17.20    2.15    0.00    0.00    0.00    0.00    0.00   51.61
08:23:31      13   27.37    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:31      14   27.37    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:31      15   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:31      16   28.12    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:31      17   30.85    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   50.00
08:23:31      18   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:31      19   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:31      20   29.79    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:31      21   28.72    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   50.00
08:23:31      22   28.42    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:31      23   28.12    0.00   20.83    8.33    0.00    0.00    0.00    0.00    0.00   42.71
08:23:31      24   28.72    0.00   19.15    3.19    0.00    0.00    0.00    0.00    0.00   48.94
08:23:31      25   27.96    0.00   18.28    2.15    0.00    0.00    0.00    0.00    0.00   51.61
08:23:31      26   28.12    0.00   19.79    3.12    0.00    0.00    0.00    0.00    0.00   48.96
08:23:31      27   29.47    0.00   17.89    4.21    0.00    0.00    0.00    0.00    0.00   48.42
08:23:31      28   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:31      29   29.90    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:31      30   29.17    0.00   17.71    3.12    0.00    0.00    0.00    0.00    0.00   50.00
08:23:31      31   26.04    0.00   20.83    1.04    0.00    0.00    0.00    0.00    0.00   52.08

08:23:31     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:32     all   28.80    0.00   18.94    2.20    0.00    0.00    0.00    0.00    0.00   50.07
08:23:32       0   30.93    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:32       1   29.79    0.00   19.15    3.19    0.00    0.00    0.00    0.00    0.00   47.87
08:23:32       2   28.42    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   49.47
08:23:32       3   29.47    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   49.47
08:23:32       4   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:32       5   30.21    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:32       6   26.60    0.00   20.21    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:32       7   28.42    0.00   21.05    5.26    0.00    0.00    0.00    0.00    0.00   45.26
08:23:32       8   29.90    0.00   18.56    3.09    0.00    0.00    0.00    0.00    0.00   48.45
08:23:32       9   29.79    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   50.00
08:23:32      10   28.87    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:23:32      11   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:32      12   29.17    0.00   18.75    4.17    0.00    0.00    0.00    0.00    0.00   47.92
08:23:32      13   28.42    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:32      14   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:32      15   27.66    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:32      16   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:32      17   28.42    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:32      18   28.12    0.00   20.83    3.12    0.00    0.00    0.00    0.00    0.00   47.92
08:23:32      19   30.93    0.00   17.53    3.09    0.00    0.00    0.00    0.00    0.00   48.45
08:23:32      20   27.84    0.00   19.59    3.09    0.00    0.00    0.00    0.00    0.00   49.48
08:23:32      21   27.66    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:32      22   28.12    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:32      23   30.53    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   48.42
08:23:32      24   27.37    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:32      25   28.72    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:32      26   29.03    0.00   17.20    3.23    0.00    0.00    0.00    0.00    0.00   50.54
08:23:32      27   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:32      28   30.93    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:23:32      29   27.55    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:23:32      30   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:32      31   27.66    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   51.06

08:23:32     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:33     all   28.83    0.00   18.51    2.42    0.00    0.00    0.00    0.00    0.00   50.23
08:23:33       0   31.58    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   49.47
08:23:33       1   28.12    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:33       2   27.66    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:33       3   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:33       4   29.17    0.00   18.75    5.21    0.00    0.00    0.00    0.00    0.00   46.88
08:23:33       5   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:33       6   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:33       7   31.25    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   48.96
08:23:33       8   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:33       9   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:33      10   29.90    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:33      11   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:33      12   28.12    0.00   18.75    5.21    0.00    0.00    0.00    0.00    0.00   47.92
08:23:33      13   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:33      14   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:33      15   28.42    0.00   17.89    3.16    0.00    0.00    0.00    0.00    0.00   50.53
08:23:33      16   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:33      17   27.96    0.00   19.35    3.23    0.00    0.00    0.00    0.00    0.00   49.46
08:23:33      18   30.93    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:33      19   28.12    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:33      20   29.79    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:33      21   29.17    0.00   18.75    5.21    0.00    0.00    0.00    0.00    0.00   46.88
08:23:33      22   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:33      23   30.21    0.00   18.75    5.21    0.00    0.00    0.00    0.00    0.00   45.83
08:23:33      24   28.42    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   49.47
08:23:33      25   28.12    0.00   19.79    3.12    0.00    0.00    0.00    0.00    0.00   48.96
08:23:33      26   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:33      27   25.81    0.00   20.43    4.30    0.00    0.00    0.00    0.00    0.00   49.46
08:23:33      28   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:33      29   29.17    0.00   17.71    4.17    0.00    0.00    0.00    0.00    0.00   48.96
08:23:33      30   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:33      31   29.79    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   53.19

08:23:33     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:34     all   29.12    0.00   18.39    2.03    0.00    0.00    0.00    0.00    0.00   50.46
08:23:34       0   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:34       1   29.17    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   48.96
08:23:34       2   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:34       3   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:34       4   27.37    0.00   21.05    3.16    0.00    0.00    0.00    0.00    0.00   48.42
08:23:34       5   26.60    0.00   20.21    3.19    0.00    0.00    0.00    0.00    0.00   50.00
08:23:34       6   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:34       7   29.17    0.00   18.75    3.12    0.00    0.00    0.00    0.00    0.00   48.96
08:23:34       8   30.21    0.00   17.71    3.12    0.00    0.00    0.00    0.00    0.00   48.96
08:23:34       9   28.87    0.00   19.59    3.09    0.00    0.00    0.00    0.00    0.00   48.45
08:23:34      10   30.11    0.00   17.20    2.15    0.00    0.00    0.00    0.00    0.00   50.54
08:23:34      11   30.21    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:34      12   31.25    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:34      13   29.47    0.00   17.89    4.21    0.00    0.00    0.00    0.00    0.00   48.42
08:23:34      14   30.85    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:34      15   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:34      16   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:34      17   28.28    0.00   20.20    2.02    0.00    0.00    0.00    0.00    0.00   49.49
08:23:34      18   30.85    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   51.06
08:23:34      19   27.96    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:34      20   29.47    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   49.47
08:23:34      21   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:34      22   29.90    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:34      23   28.42    0.00   18.95    4.21    0.00    0.00    0.00    0.00    0.00   48.42
08:23:34      24   28.42    0.00   18.95    4.21    0.00    0.00    0.00    0.00    0.00   48.42
08:23:34      25   28.57    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:34      26   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:34      27   30.53    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   49.47
08:23:34      28   30.93    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:23:34      29   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:34      30   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:23:34      31   27.37    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   53.68

08:23:34     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:35     all   28.17    0.00   18.67    1.57    0.00    0.00    0.00    0.00    0.00   51.59
08:23:35       0   30.21    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   48.96
08:23:35       1   27.66    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:35       2   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:35       3   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:35       4   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:35       5   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:35       6   30.53    0.00   15.79    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:35       7   27.37    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:35       8   28.12    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:35       9   28.12    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:35      10   29.47    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   49.47
08:23:35      11   26.04    0.00   21.88    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:35      12   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:35      13   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:35      14   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:35      15   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:35      16   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:35      17   29.03    0.00   16.13    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:23:35      18   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:35      19   28.12    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:35      20   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:35      21   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:35      22   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:35      23   27.08    0.00   20.83    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:35      24   25.26    0.00   21.05    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:35      25   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:35      26   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:35      27   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:35      28   26.88    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:23:35      29   27.66    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:23:35      30   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:35      31   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08

08:23:35     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:36     all   28.93    0.00   18.25    1.54    0.00    0.00    0.00    0.00    0.00   51.28
08:23:36       0   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:36       1   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:36       2   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:36       3   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:36       4   29.17    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:36       5   28.72    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   51.06
08:23:36       6   30.53    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:36       7   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:36       8   27.55    0.00   21.43    2.04    0.00    0.00    0.00    0.00    0.00   48.98
08:23:36       9   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:36      10   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:36      11   31.25    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:36      12   30.53    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:36      13   29.47    0.00   17.89    0.00    0.00    0.00    0.00    0.00    0.00   52.63
08:23:36      14   28.42    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   49.47
08:23:36      15   31.25    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:36      16   29.79    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:36      17   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:36      18   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:36      19   29.03    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:36      20   26.32    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:36      21   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:36      22   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:36      23   30.21    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:36      24   27.37    0.00   18.95    3.16    0.00    0.00    0.00    0.00    0.00   50.53
08:23:36      25   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:36      26   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:36      27   28.57    0.00   18.37    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:23:36      28   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:36      29   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:36      30   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:36      31   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19

08:23:36     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:37     all   27.78    0.00   18.06    1.63    0.00    0.00    0.00    0.00    0.00   52.54
08:23:37       0   27.66    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:37       1   28.87    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:23:37       2   30.11    0.00   16.13    2.15    0.00    0.00    0.00    0.00    0.00   51.61
08:23:37       3   26.88    0.00   19.35    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:37       4   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:37       5   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:37       6   27.17    0.00   17.39    0.00    0.00    0.00    0.00    0.00    0.00   55.43
08:23:37       7   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:37       8   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:37       9   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:37      10   27.66    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:37      11   29.79    0.00   15.96    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:37      12   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:37      13   26.60    0.00   19.15    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:37      14   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:37      15   27.66    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:37      16   25.81    0.00   19.35    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:23:37      17   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:37      18   27.37    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:37      19   27.96    0.00   16.13    2.15    0.00    0.00    0.00    0.00    0.00   53.76
08:23:37      20   27.08    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:37      21   26.88    0.00   18.28    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:23:37      22   26.32    0.00   20.00    3.16    0.00    0.00    0.00    0.00    0.00   50.53
08:23:37      23   30.11    0.00   15.05    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:23:37      24   28.57    0.00   16.48    1.10    0.00    0.00    0.00    0.00    0.00   53.85
08:23:37      25   27.37    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:37      26   28.72    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:37      27   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:37      28   26.32    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   52.63
08:23:37      29   27.08    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   53.12
08:23:37      30   28.26    0.00   17.39    1.09    0.00    0.00    0.00    0.00    0.00   53.26
08:23:37      31   26.04    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   53.12

08:23:37     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:38     all   28.34    0.00   18.62    1.53    0.00    0.00    0.00    0.00    0.00   51.51
08:23:38       0   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:38       1   29.79    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:38       2   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:38       3   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:38       4   28.12    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:38       5   31.96    0.00   15.46    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:38       6   24.24    0.00   24.24    2.02    0.00    0.00    0.00    0.00    0.00   49.49
08:23:38       7   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:38       8   30.21    0.00   16.67    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:38       9   29.79    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:38      10   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:38      11   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:38      12   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:38      13   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:38      14   29.90    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:38      15   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:38      16   26.32    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:38      17   28.87    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:38      18   27.08    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:38      19   28.57    0.00   20.41    2.04    0.00    0.00    0.00    0.00    0.00   48.98
08:23:38      20   30.53    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:38      21   27.55    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   51.02
08:23:38      22   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:38      23   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:38      24   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:38      25   29.79    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:38      26   27.55    0.00   19.39    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:23:38      27   27.84    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:38      28   25.53    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:23:38      29   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:38      30   27.08    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   53.12
08:23:38      31   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08

08:23:38     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:39     all   28.95    0.00   18.62    1.49    0.00    0.00    0.00    0.00    0.00   50.94
08:23:39       0   28.42    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:39       1   28.28    0.00   20.20    2.02    0.00    0.00    0.00    0.00    0.00   49.49
08:23:39       2   28.42    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:39       3   28.12    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:39       4   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:39       5   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:39       6   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:39       7   28.87    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   50.52
08:23:39       8   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:39       9   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:39      10   29.90    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   49.48
08:23:39      11   28.42    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:39      12   30.21    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   51.04
08:23:39      13   29.90    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:23:39      14   30.21    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:39      15   27.37    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:39      16   30.21    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:39      17   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:39      18   27.55    0.00   20.41    1.02    0.00    0.00    0.00    0.00    0.00   51.02
08:23:39      19   28.72    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   51.06
08:23:39      20   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:39      21   28.12    0.00   18.75    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:39      22   29.17    0.00   19.79    1.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:39      23   27.84    0.00   20.62    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:23:39      24   29.90    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   50.52
08:23:39      25   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:39      26   31.25    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:39      27   30.21    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:39      28   27.84    0.00   19.59    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:39      29   29.47    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   53.68
08:23:39      30   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:39      31   29.90    0.00   17.53    2.06    0.00    0.00    0.00    0.00    0.00   50.52

08:23:39     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:40     all   28.75    0.00   18.06    1.57    0.00    0.00    0.00    0.00    0.00   51.62
08:23:40       0   29.90    0.00   17.53    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:40       1   28.72    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:40       2   29.17    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:40       3   31.58    0.00   15.79    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:40       4   30.53    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   49.47
08:23:40       5   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:40       6   27.66    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:40       7   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:40       8   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:40       9   28.87    0.00   18.56    1.03    0.00    0.00    0.00    0.00    0.00   51.55
08:23:40      10   27.66    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:40      11   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:40      12   29.47    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:40      13   27.08    0.00   19.79    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:40      14   27.37    0.00   18.95    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:40      15   29.59    0.00   17.35    1.02    0.00    0.00    0.00    0.00    0.00   52.04
08:23:40      16   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:40      17   29.47    0.00   16.84    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:40      18   29.17    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   52.08
08:23:40      19   27.84    0.00   18.56    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:40      20   25.26    0.00   21.05    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:40      21   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:40      22   28.42    0.00   17.89    3.16    0.00    0.00    0.00    0.00    0.00   50.53
08:23:40      23   30.61    0.00   17.35    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:40      24   28.72    0.00   17.02    2.13    0.00    0.00    0.00    0.00    0.00   52.13
08:23:40      25   28.87    0.00   18.56    3.09    0.00    0.00    0.00    0.00    0.00   49.48
08:23:40      26   28.12    0.00   18.75    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:40      27   29.17    0.00   17.71    1.04    0.00    0.00    0.00    0.00    0.00   52.08
08:23:40      28   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:40      29   28.42    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:40      30   26.80    0.00   19.59    2.06    0.00    0.00    0.00    0.00    0.00   51.55
08:23:40      31   26.32    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   52.63

08:23:40     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:41     all   28.16    0.00   18.31    1.53    0.00    0.00    0.00    0.00    0.00   52.01
08:23:41       0   28.72    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:41       1   27.37    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:41       2   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:41       3   30.53    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:41       4   26.09    0.00   19.57    1.09    0.00    0.00    0.00    0.00    0.00   53.26
08:23:41       5   29.47    0.00   16.84    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:41       6   27.96    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:23:41       7   26.32    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:41       8   28.42    0.00   17.89    2.11    0.00    0.00    0.00    0.00    0.00   51.58
08:23:41       9   28.72    0.00   17.02    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:41      10   30.21    0.00   16.67    2.08    0.00    0.00    0.00    0.00    0.00   51.04
08:23:41      11   29.79    0.00   18.09    2.13    0.00    0.00    0.00    0.00    0.00   50.00
08:23:41      12   30.85    0.00   14.89    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:41      13   27.66    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:41      14   27.17    0.00   18.48    1.09    0.00    0.00    0.00    0.00    0.00   53.26
08:23:41      15   27.66    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   52.13
08:23:41      16   27.66    0.00   18.09    1.06    0.00    0.00    0.00    0.00    0.00   53.19
08:23:41      17   29.03    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   52.69
08:23:41      18   26.88    0.00   20.43    1.08    0.00    0.00    0.00    0.00    0.00   51.61
08:23:41      19   29.47    0.00   17.89    1.05    0.00    0.00    0.00    0.00    0.00   51.58
08:23:41      20   28.72    0.00   15.96    1.06    0.00    0.00    0.00    0.00    0.00   54.26
08:23:41      21   26.32    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:41      22   28.42    0.00   18.95    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:41      23   28.57    0.00   19.39    2.04    0.00    0.00    0.00    0.00    0.00   50.00
08:23:41      24   27.37    0.00   20.00    2.11    0.00    0.00    0.00    0.00    0.00   50.53
08:23:41      25   27.96    0.00   17.20    1.08    0.00    0.00    0.00    0.00    0.00   53.76
08:23:41      26   27.17    0.00   18.48    1.09    0.00    0.00    0.00    0.00    0.00   53.26
08:23:41      27   30.21    0.00   17.71    2.08    0.00    0.00    0.00    0.00    0.00   50.00
08:23:41      28   26.60    0.00   20.21    2.13    0.00    0.00    0.00    0.00    0.00   51.06
08:23:41      29   27.96    0.00   17.20    2.15    0.00    0.00    0.00    0.00    0.00   52.69
08:23:41      30   26.32    0.00   20.00    1.05    0.00    0.00    0.00    0.00    0.00   52.63
08:23:41      31   27.66    0.00   19.15    1.06    0.00    0.00    0.00    0.00    0.00   52.13

08:23:41     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:42     all    1.35    0.00    2.26    0.09    0.00    0.00    0.00    0.00    0.00   96.30
08:23:42       0    2.00    0.00    2.00    0.00    0.00    0.00    0.00    0.00    0.00   96.00
08:23:42       1    1.98    0.00    2.97    0.00    0.00    0.00    0.00    0.00    0.00   95.05
08:23:42       2    2.02    0.00    2.02    0.00    0.00    0.00    0.00    0.00    0.00   95.96
08:23:42       3    2.02    0.00    1.01    0.00    0.00    0.00    0.00    0.00    0.00   96.97
08:23:42       4    1.98    0.00    2.97    0.00    0.00    0.00    0.00    0.00    0.00   95.05
08:23:42       5    1.01    0.00    2.02    0.00    0.00    0.00    0.00    0.00    0.00   96.97
08:23:42       6    1.00    0.00    3.00    0.00    0.00    0.00    0.00    0.00    0.00   96.00
08:23:42       7    2.00    0.00    2.00    0.00    0.00    0.00    0.00    0.00    0.00   96.00
08:23:42       8    1.00    0.00    3.00    0.00    0.00    0.00    0.00    0.00    0.00   96.00
08:23:42       9    1.00    0.00    2.00    0.00    0.00    0.00    0.00    0.00    0.00   97.00
08:23:42      10    2.00    0.00    2.00    0.00    0.00    0.00    0.00    0.00    0.00   96.00
08:23:42      11    2.00    0.00    2.00    0.00    0.00    0.00    0.00    0.00    0.00   96.00
08:23:42      12    1.01    0.00    2.02    0.00    0.00    0.00    0.00    0.00    0.00   96.97
08:23:42      13    1.00    0.00    3.00    1.00    0.00    0.00    0.00    0.00    0.00   95.00
08:23:42      14    2.97    0.00    1.98    0.99    0.00    0.00    0.00    0.00    0.00   94.06
08:23:42      15    1.00    0.00    3.00    0.00    0.00    0.00    0.00    0.00    0.00   96.00
08:23:42      16    1.01    0.00    2.02    0.00    0.00    0.00    0.00    0.00    0.00   96.97
08:23:42      17    1.00    0.00    3.00    0.00    0.00    0.00    0.00    0.00    0.00   96.00
08:23:42      18    0.99    0.00    2.97    0.99    0.00    0.00    0.00    0.00    0.00   95.05
08:23:42      19    0.00    0.00    3.06    0.00    0.00    0.00    0.00    0.00    0.00   96.94
08:23:42      20    2.00    0.00    2.00    0.00    0.00    0.00    0.00    0.00    0.00   96.00
08:23:42      21    1.01    0.00    2.02    0.00    0.00    0.00    0.00    0.00    0.00   96.97
08:23:42      22    1.01    0.00    2.02    0.00    0.00    0.00    0.00    0.00    0.00   96.97
08:23:42      23    1.01    0.00    2.02    0.00    0.00    0.00    0.00    0.00    0.00   96.97
08:23:42      24    1.01    0.00    2.02    0.00    0.00    0.00    0.00    0.00    0.00   96.97
08:23:42      25    1.01    0.00    2.02    0.00    0.00    0.00    0.00    0.00    0.00   96.97
08:23:42      26    1.01    0.00    2.02    0.00    0.00    0.00    0.00    0.00    0.00   96.97
08:23:42      27    1.01    0.00    1.01    0.00    0.00    0.00    0.00    0.00    0.00   97.98
08:23:42      28    1.01    0.00    2.02    0.00    0.00    0.00    0.00    0.00    0.00   96.97
08:23:42      29    2.00    0.00    2.00    0.00    0.00    0.00    0.00    0.00    0.00   96.00
08:23:42      30    1.00    0.00    3.00    0.00    0.00    0.00    0.00    0.00    0.00   96.00
08:23:42      31    1.00    0.00    2.00    0.00    0.00    0.00    0.00    0.00    0.00   97.00

08:23:42     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:23:43     all    0.03    0.00    0.06    0.00    0.00    0.00    0.00    0.00    0.00   99.91
08:23:43       0    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43       1    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43       2    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43       3    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43       4    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43       5    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43       6    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43       7    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43       8    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43       9    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      10    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      11    0.00    0.00    0.99    0.00    0.00    0.00    0.00    0.00    0.00   99.01
08:23:43      12    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      13    0.00    0.00    0.99    0.00    0.00    0.00    0.00    0.00    0.00   99.01
08:23:43      14    1.01    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00   98.99
08:23:43      15    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      16    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      17    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      18    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      19    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      20    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      21    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      22    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      23    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      24    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      25    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      26    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      27    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      28    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      29    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      30    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
08:23:43      31    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00

```

---

## Command 11: pg_wait_events

### Command
```bash
bash -c 'for i in $(seq 1 130); do echo "=== $(date '"'"'+%H:%M:%S'"'"') ==="; sudo -u postgres psql -t -c "SELECT coalesce(wait_event_type,'"'"'CPU'"'"') as type, coalesce(wait_event,'"'"'Running'"'"') as event, count(*) as cnt FROM pg_stat_activity WHERE state='"'"'active'"'"' AND pid<>pg_backend_pid() GROUP BY 1,2 ORDER BY 3 DESC LIMIT 10"; sleep 1; done'
```

### Output
```
=== 08:21:39 ===

=== 08:21:40 ===

=== 08:21:41 ===
 Client | ClientRead |  12
 CPU    | Running    |  11

=== 08:21:42 ===
 LWLock | WALWrite      |  81
 Lock   | transactionid |   4
 Client | ClientRead    |   1
 IO     | WALSync       |   1

=== 08:21:43 ===
 LWLock | WALWrite      |  72
 CPU    | Running       |   4
 Client | ClientRead    |   1
 IO     | WALSync       |   1
 Lock   | transactionid |   1

=== 08:21:44 ===
 LWLock  | WALWrite      |  94
 Lock    | transactionid |   3
 CPU     | Running       |   1
 IO      | WALSync       |   1
 Timeout | SpinDelay     |   1

=== 08:21:45 ===
 LWLock | WALWrite      |  70
 CPU    | Running       |   8
 Client | ClientRead    |   3
 IO     | WALSync       |   1
 LWLock | BufferContent |   1
 Lock   | transactionid |   1

=== 08:21:46 ===
 LWLock | WALWrite      |  96
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:21:47 ===
 LWLock | WALWrite      |  92
 Lock   | transactionid |   7
 IO     | WALSync       |   1

=== 08:21:48 ===
 LWLock | WALWrite      |  93
 Lock   | transactionid |   5
 IO     | WALSync       |   1
 Lock   | tuple         |   1

=== 08:21:49 ===
 LWLock  | WALInsert     |  80
 Timeout | SpinDelay     |   7
 LWLock  | BufferContent |   5

=== 08:21:50 ===
 LWLock | WALWrite      |  56
 CPU    | Running       |  13
 Client | ClientRead    |   6
 Lock   | transactionid |   3
 IO     | WALSync       |   1

=== 08:21:51 ===
 LWLock  | WALWrite      |  89
 Lock    | transactionid |   7
 IO      | WALSync       |   1
 Timeout | SpinDelay     |   1

=== 08:21:52 ===
 LWLock | WALWrite      |  94
 Lock   | transactionid |   4
 CPU    | Running       |   1
 IO     | WALSync       |   1

=== 08:21:53 ===
 LWLock | WALWrite      |  69
 Client | ClientRead    |   7
 CPU    | Running       |   4
 Lock   | transactionid |   3
 IO     | WALSync       |   1

=== 08:21:54 ===
 LWLock | WALWrite      |  46
 CPU    | Running       |  16
 Client | ClientRead    |   4
 Lock   | transactionid |   3
 IO     | WALSync       |   1

=== 08:21:55 ===
 LWLock | WALWrite |  99
 IO     | WALSync  |   1

=== 08:21:56 ===
 LWLock | WALWrite      |  91
 Lock   | transactionid |   5
 IO     | WALSync       |   1

=== 08:21:57 ===
 LWLock | WALWrite      |  65
 CPU    | Running       |   7
 Client | ClientRead    |   5
 IO     | WALSync       |   1
 Lock   | transactionid |   1

=== 08:21:58 ===
 LWLock | WALWrite      |  44
 CPU    | Running       |  11
 Client | ClientRead    |   9
 Lock   | transactionid |   3
 IO     | WALSync       |   1

=== 08:21:59 ===
 LWLock | WALWrite      |  96
 Lock   | transactionid |   3
 IO     | WALSync       |   1

=== 08:22:00 ===
 LWLock | WALWrite      |  96
 Lock   | transactionid |   3
 IO     | WALSync       |   1

=== 08:22:01 ===
 LWLock | WALWrite      |  66
 Client | ClientRead    |   7
 CPU    | Running       |   3
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:22:02 ===
 LWLock | WALWrite      |  61
 CPU    | Running       |   7
 Client | ClientRead    |   3
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:22:04 ===
 LWLock | WALWrite      |  38
 CPU    | Running       |  13
 Client | ClientRead    |   7
 IO     | WALSync       |   1
 LWLock | BufferContent |   1
 Lock   | transactionid |   1

=== 08:22:05 ===
 LWLock | WALWrite      |  59
 CPU    | Running       |   9
 Client | ClientRead    |   2
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:22:06 ===
 LWLock | WALWrite      |  95
 Lock   | transactionid |   3
 CPU    | Running       |   1
 IO     | WALSync       |   1

=== 08:22:07 ===
 LWLock | WALWrite      |  78
 Lock   | transactionid |   5
 CPU    | Running       |   2
 IO     | WALSync       |   1

=== 08:22:08 ===
 LWLock | WALWrite      |  54
 CPU    | Running       |   7
 Lock   | transactionid |   6
 Client | ClientRead    |   3
 IO     | WALSync       |   1

=== 08:22:09 ===
 LWLock | WALWrite      |  62
 CPU    | Running       |   9
 Client | ClientRead    |   6
 Lock   | transactionid |   4
 IO     | WALSync       |   1

=== 08:22:10 ===
 LWLock  | WALWrite      |  93
 Lock    | transactionid |   4
 IO      | WALSync       |   1
 Lock    | tuple         |   1
 Timeout | SpinDelay     |   1

=== 08:22:11 ===
 LWLock | WALWrite      |  47
 CPU    | Running       |  16
 Client | ClientRead    |   2
 IO     | WALSync       |   1
 LWLock | XactSLRU      |   1
 Lock   | transactionid |   1

=== 08:22:12 ===
 LWLock | WALWrite       |  92
 Lock   | transactionid  |   5
 IO     | DataFileExtend |   1
 IO     | WALSync        |   1
 Lock   | extend         |   1

=== 08:22:13 ===
 LWLock | WALWrite      |  55
 CPU    | Running       |  14
 Client | ClientRead    |   3
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:22:14 ===
 LWLock | WALWrite      |  59
 CPU    | Running       |  13
 Client | ClientRead    |   2
 IO     | WALSync       |   1
 Lock   | transactionid |   1

=== 08:22:15 ===
 LWLock | WALWrite      |  52
 Client | ClientRead    |  17
 CPU    | Running       |   8
 Lock   | transactionid |   5
 IO     | WALSync       |   1

=== 08:22:16 ===
 LWLock | WALWrite      |  92
 Lock   | transactionid |   7
 IO     | WALSync       |   1

=== 08:22:17 ===
 LWLock | WALWrite      |  53
 CPU    | Running       |   8
 Client | ClientRead    |   6
 Lock   | transactionid |   3
 IO     | WALSync       |   1

=== 08:22:18 ===
 LWLock | WALWrite      |  94
 Lock   | transactionid |   4
 IO     | WALSync       |   1

=== 08:22:19 ===
 LWLock | WALWrite      |  42
 CPU    | Running       |  19
 Client | ClientRead    |   9
 IO     | WALSync       |   1
 Lock   | transactionid |   1

=== 08:22:20 ===
 LWLock | WALWrite      |  92
 Lock   | transactionid |   6
 CPU    | Running       |   1
 IO     | WALSync       |   1

=== 08:22:21 ===
 LWLock | WALWrite      |  59
 Client | ClientRead    |   5
 CPU    | Running       |   4
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:22:22 ===
 LWLock | WALWrite      |  95
 Lock   | transactionid |   4
 IO     | WALSync       |   1

=== 08:22:23 ===
 LWLock | WALWrite      |  83
 Lock   | transactionid |   6
 CPU    | Running       |   1
 IO     | WALSync       |   1

=== 08:22:24 ===
 LWLock | WALWrite      |  92
 Lock   | transactionid |   6
 IO     | WALSync       |   1
 Lock   | tuple         |   1

=== 08:22:25 ===
 LWLock | WALWrite      |  86
 Lock   | transactionid |   2
 CPU    | Running       |   1
 IO     | WALSync       |   1

=== 08:22:26 ===
 LWLock | WALWrite      |  94
 Lock   | transactionid |   5
 IO     | WALSync       |   1

=== 08:22:27 ===
 LWLock | WALWrite      |  93
 Lock   | transactionid |   5
 IO     | WALSync       |   1

=== 08:22:28 ===
 LWLock | WALWrite      |  95
 Lock   | transactionid |   3
 CPU    | Running       |   1
 IO     | WALSync       |   1

=== 08:22:29 ===
 LWLock | WALWrite      |  79
 Lock   | transactionid |   5
 Client | ClientRead    |   2
 IO     | WALSync       |   1

=== 08:22:30 ===
 LWLock | WALWrite      |  97
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:22:31 ===
 LWLock | WALWrite      |  97
 IO     | WALSync       |   1
 Lock   | transactionid |   1

=== 08:22:32 ===
 LWLock | WALWrite      |  55
 CPU    | Running       |  15
 Client | ClientRead    |   2
 IO     | WALSync       |   1
 Lock   | transactionid |   1

=== 08:22:33 ===
 LWLock | WALWrite      |  61
 CPU    | Running       |   9
 Client | ClientRead    |   7
 Lock   | transactionid |   5
 IO     | WALSync       |   1

=== 08:22:34 ===
 LWLock | WALWrite      |  87
 Lock   | transactionid |   3
 Client | ClientRead    |   2
 IO     | WALSync       |   1

=== 08:22:35 ===
 LWLock | WALWrite      |  90
 Lock   | transactionid |   8
 IO     | WALSync       |   1
 Lock   | tuple         |   1

=== 08:22:37 ===
 LWLock | WALWrite   |  65
 CPU    | Running    |   7
 Client | ClientRead |   6
 IO     | WALSync    |   1

=== 08:22:38 ===
 LWLock | WALWrite      |  90
 Lock   | transactionid |   2
 Client | ClientRead    |   1
 IO     | WALSync       |   1

=== 08:22:39 ===
 LWLock | WALWrite      |  50
 Client | ClientRead    |  11
 CPU    | Running       |  10
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:22:40 ===
 LWLock | WALWrite      |  89
 Lock   | transactionid |   4
 Client | ClientRead    |   2
 IO     | WALSync       |   1

=== 08:22:41 ===
 LWLock | WALWrite      |  48
 CPU    | Running       |   9
 Client | ClientRead    |   5
 IO     | WALSync       |   1
 Lock   | transactionid |   1

=== 08:22:42 ===
 LWLock | WALWrite      |  58
 CPU    | Running       |   6
 Client | ClientRead    |   6
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:22:43 ===
 LWLock | WALWrite   |  46
 Client | ClientRead |  13
 CPU    | Running    |   9
 IO     | WALSync    |   1

=== 08:22:44 ===
 LWLock | WALWrite      |  93
 Lock   | transactionid |   6
 IO     | WALSync       |   1

=== 08:22:45 ===
 LWLock  | WALWrite      |  87
 Lock    | transactionid |   4
 CPU     | Running       |   1
 IO      | WALSync       |   1
 Timeout | SpinDelay     |   1

=== 08:22:46 ===
 LWLock | WALWrite      |  57
 Client | ClientRead    |   8
 CPU    | Running       |   3
 Lock   | transactionid |   3
 LWLock | WALInsert     |   2
 IO     | WALSync       |   1

=== 08:22:47 ===
 LWLock | WALWrite      |  81
 Lock   | transactionid |   5
 Client | ClientRead    |   2
 IO     | WALSync       |   1

=== 08:22:48 ===
 LWLock | WALWrite      |  92
 Lock   | transactionid |   5
 Lock   | tuple         |   2
 IO     | WALSync       |   1

=== 08:22:49 ===
 LWLock | WALWrite      |  48
 CPU    | Running       |  14
 Client | ClientRead    |   5
 IO     | WALSync       |   1
 Lock   | transactionid |   1

=== 08:22:50 ===
 LWLock  | WALWrite   |  35
 CPU     | Running    |  15
 Client  | ClientRead |   8
 Timeout | SpinDelay  |   4
 IO      | WALSync    |   1

=== 08:22:51 ===
 LWLock | WALWrite      |  87
 Lock   | transactionid |   5
 CPU    | Running       |   2
 IO     | WALSync       |   1

=== 08:22:52 ===
 LWLock | WALWrite   |  40
 CPU    | Running    |  14
 Client | ClientRead |   4
 IO     | WALSync    |   1

=== 08:22:53 ===
 LWLock | WALWrite      |  56
 CPU    | Running       |  17
 Client | ClientRead    |  14
 IO     | WALSync       |   1
 LWLock | ProcArray     |   1
 Lock   | transactionid |   1

=== 08:22:54 ===
 LWLock | WALWrite      |  43
 CPU    | Running       |  18
 Client | ClientRead    |   7
 Lock   | transactionid |   2
 LWLock | BufferContent |   1
 IO     | WALSync       |   1
 LWLock | XactSLRU      |   1

=== 08:22:55 ===
 LWLock | WALWrite      |  84
 Lock   | transactionid |   4
 CPU    | Running       |   3
 Client | ClientRead    |   1
 IO     | WALSync       |   1

=== 08:22:56 ===
 LWLock | WALWrite      |  66
 CPU    | Running       |  11
 Lock   | transactionid |   4
 Client | ClientRead    |   2
 IO     | WALSync       |   1

=== 08:22:57 ===
 LWLock | WALWrite      |  95
 Lock   | transactionid |   4
 IO     | WALSync       |   1

=== 08:22:58 ===
 LWLock | WALWrite      |  86
 Lock   | transactionid |  10
 CPU    | Running       |   2
 IO     | WALSync       |   1
 Lock   | tuple         |   1

=== 08:22:59 ===
 LWLock | WALWrite      |  43
 CPU    | Running       |  13
 Client | ClientRead    |   3
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:23:00 ===
 LWLock | WALWrite      |  38
 CPU    | Running       |  23
 Client | ClientRead    |   4
 Lock   | transactionid |   3
 IO     | WALSync       |   1

=== 08:23:01 ===
 LWLock | WALWrite      |  94
 Lock   | transactionid |   5
 IO     | WALSync       |   1

=== 08:23:02 ===
 LWLock | WALWrite      |  93
 Lock   | transactionid |   6
 IO     | WALSync       |   1

=== 08:23:03 ===
 LWLock | WALWrite      |  95
 Lock   | transactionid |   4
 IO     | WALSync       |   1

=== 08:23:04 ===
 LWLock | WALWrite      |  85
 Lock   | transactionid |   4
 IO     | WALSync       |   1

=== 08:23:05 ===
 LWLock | WALWrite      |  64
 Client | ClientRead    |  19
 CPU    | Running       |  14
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:23:06 ===
 LWLock | WALWrite      |  90
 Lock   | transactionid |   4
 Client | ClientRead    |   1
 IO     | WALSync       |   1

=== 08:23:07 ===
 LWLock | WALWrite      |  94
 Lock   | transactionid |   4
 IO     | WALSync       |   1
 Lock   | tuple         |   1

=== 08:23:08 ===
 LWLock | WALWrite      |  96
 Lock   | transactionid |   3
 CPU    | Running       |   1

=== 08:23:09 ===
 LWLock | WALWrite      |  97
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:23:11 ===
 LWLock | WALWrite      |  83
 Client | ClientRead    |   3
 CPU    | Running       |   2
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:23:12 ===
 LWLock | WALWrite   |  39
 CPU    | Running    |  23
 Client | ClientRead |  11
 IO     | WALSync    |   1

=== 08:23:13 ===
 LWLock | WALWrite      |  56
 CPU    | Running       |   9
 Client | ClientRead    |   6
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:23:14 ===
 LWLock | WALWrite      |  97
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:23:15 ===
 LWLock | WALWrite      |  96
 Lock   | transactionid |   3
 IO     | WALSync       |   1

=== 08:23:16 ===
 LWLock | WALWrite      |  96
 Lock   | transactionid |   3
 IO     | WALSync       |   1

=== 08:23:17 ===
 LWLock | WALWrite      |  66
 Client | ClientRead    |   6
 Lock   | transactionid |   6
 CPU    | Running       |   3
 IO     | WALSync       |   1

=== 08:23:18 ===
 LWLock | WALWrite |  93
 IO     | WALSync  |   1

=== 08:23:19 ===
 LWLock | WALWrite      |  48
 CPU    | Running       |  20
 Client | ClientRead    |   3
 IO     | WALSync       |   1
 Lock   | transactionid |   1

=== 08:23:20 ===
 LWLock | WALWrite      |  97
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:23:21 ===
 LWLock | WALWrite      |  86
 Lock   | transactionid |   7
 CPU    | Running       |   1
 IO     | WALSync       |   1

=== 08:23:22 ===
 LWLock  | WALWrite      |  48
 CPU     | Running       |  14
 Timeout | SpinDelay     |   4
 Client  | ClientRead    |   3
 IO      | WALSync       |   1
 Lock    | transactionid |   1

=== 08:23:23 ===
 LWLock | WALWrite      |  55
 CPU    | Running       |  15
 Client | ClientRead    |  15
 Lock   | transactionid |   3
 IO     | WALSync       |   1

=== 08:23:24 ===
 LWLock | WALWrite      |  93
 Lock   | transactionid |   6
 IO     | WALSync       |   1

=== 08:23:25 ===
 LWLock | WALWrite      |  78
 CPU    | Running       |  10
 Client | ClientRead    |   6
 Lock   | transactionid |   5
 IO     | WALSync       |   1

=== 08:23:26 ===
 LWLock | WALWrite      |  96
 Lock   | transactionid |   2
 IO     | WALSync       |   1
 IO     | WALWrite      |   1

=== 08:23:27 ===
 LWLock | WALWrite      |  98
 IO     | WALSync       |   1
 Lock   | transactionid |   1

=== 08:23:28 ===
 LWLock | WALWrite      |  88
 Lock   | transactionid |   4
 CPU    | Running       |   2
 IO     | WALSync       |   1

=== 08:23:29 ===
 LWLock | WALWrite      |  95
 Lock   | transactionid |   3
 CPU    | Running       |   1
 IO     | WALSync       |   1

=== 08:23:30 ===
 LWLock | WALWrite      |  93
 Lock   | transactionid |   5
 CPU    | Running       |   1
 IO     | WALSync       |   1

=== 08:23:31 ===
 LWLock | WALWrite      |  62
 Client | ClientRead    |   7
 CPU    | Running       |   6
 Lock   | transactionid |   4
 IO     | WALSync       |   1

=== 08:23:32 ===
 LWLock | WALWrite      |  76
 CPU    | Running       |   3
 Client | ClientRead    |   3
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:23:33 ===
 LWLock | WALWrite      |  83
 CPU    | Running       |   2
 Lock   | transactionid |   2
 Client | ClientRead    |   1
 IO     | WALSync       |   1

=== 08:23:34 ===
 LWLock | WALWrite      |  92
 Lock   | transactionid |   4
 IO     | WALSync       |   1

=== 08:23:35 ===
 LWLock | WALWrite      |  97
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:23:36 ===
 LWLock | WALWrite      |  90
 Lock   | transactionid |   4
 IO     | WALSync       |   1

=== 08:23:37 ===
 LWLock | WALWrite   |  66
 CPU    | Running    |  11
 Client | ClientRead |   4
 IO     | WALSync    |   1

=== 08:23:38 ===
 LWLock | WALWrite      |  89
 CPU    | Running       |   6
 Lock   | transactionid |   4
 IO     | WALSync       |   1

=== 08:23:39 ===
 LWLock | WALWrite      |  45
 CPU    | Running       |  13
 Client | ClientRead    |   4
 LWLock | WALInsert     |   3
 LWLock | BufferContent |   2
 Lock   | transactionid |   2
 IO     | WALSync       |   1

=== 08:23:40 ===
 LWLock | WALWrite             |  54
 Client | ClientRead           |  13
 CPU    | Running              |   7
 Lock   | transactionid        |   2
 IPC    | ProcArrayGroupUpdate |   1
 IO     | WALSync              |   1
 LWLock | ProcArray            |   1

=== 08:23:41 ===

=== 08:23:42 ===


```

---

## Command 12: pg_checkpoint_log

### Command
```bash
bash -c 'timeout 130s tail -f /var/log/postgresql/postgresql-16-main.log 2>/dev/null | grep --line-buffered -i checkpoint || true'
```

### Output
```

```

---

## Command 13: End:pg_stat_bgwriter

### Command
```bash
sudo -u postgres psql -c 'SELECT buffers_checkpoint, buffers_clean, buffers_backend, buffers_alloc FROM pg_stat_bgwriter'
```

### Output
```
 buffers_checkpoint | buffers_clean | buffers_backend | buffers_alloc 
--------------------+---------------+-----------------+---------------
                  0 |        211034 |               0 |        397509
(1 row)


```

---
