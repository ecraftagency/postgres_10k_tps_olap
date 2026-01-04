# Benchmark: [POSTGRES DISK] pgbench TPC-B - PostgreSQL OLTP

**Date:** 2026-01-03 15:06:23
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

Linux ip-10-0-1-227 6.14.0-1018-aws #18~24.04.1-Ubuntu SMP Mon Nov 24 19:32:52 UTC 2025 aarch64 aarch64 aarch64 GNU/Linux
Architecture:                            aarch64
CPU(s):                                  8
Model name:                              Neoverse-V2
total        used        free      shared  buff/cache   available
Mem:            15Gi       5.1Gi       429Mi       4.2Gi        14Gi        10Gi
Swap:             0B          0B          0B

=== OS TUNING ===
vm.swappiness = 1
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
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

       Update Time : Sat Jan  3 14:45:20 2026
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

       Update Time : Sat Jan  3 14:45:19 2026
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
/dev/md1        120G   29G   92G  24% /wal

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
sudo -u postgres psql -c SELECT pg_stat_reset(); SELECT pg_stat_reset_shared('bgwriter');
```

### Output
```
/bin/sh: 1: Syntax error: "(" unexpected

```

---

## Command 7: pgbench

### Command
```bash
sudo -u postgres pgbench -c 100 -j 6 -T 60 -P 5 -b tpcb-like -l --log-prefix=pgbench_tpcb pgbench
```

### Output
```
pgbench (16.11 (Ubuntu 16.11-1.pgdg24.04+1))
starting vacuum...end.
pgbench: error: could not open logfile "pgbench_tpcb.38333.1": Permission denied
pgbench: error: could not open logfile "pgbench_tpcb.38333.2": Permission denied

```

---

## Command 8: meminfo

### Command
```bash
bash -c while true; do date '+%H:%M:%S'; grep -E 'Dirty|Writeback' /proc/meminfo; sleep 1; done
```

### Output
```
No output
```

---

## Command 9: dstat

### Command
```bash
dstat -tcmdr --disk-util 1 70
```

### Output
```
----system---- ----total-usage---- ------memory-usage----- -dsk/total- --io/total- nvme nvme nvme nvme nvme nvme nvme nvme nvme nvme nvme nvme nvme nvme nvme nvme nvme
     time     |usr sys idl wai stl| used  free  buf   cach| read  writ| read  writ|util:util:util:util:util:util:util:util:util:util:util:util:util:util:util:util:util
03-01 15:06:19|                   |4805M  419M   22M   14G|           |           |    :    :    :    :    :    :    :    :    :    :    :    :    :    :    :    :    
03-01 15:06:20|  0   0 100   0   0|4798M  426M   22M   14G|   0     0 |   0     0 |   0:   0:   0:   0:   0:   0:   0:   0:   0:   0:   0:   0:   0:   0:   0:   0:   0
03-01 15:06:21|  0   0  99   1   0|4783M  441M   22M   14G| 732k   40M|28.5  89.0 |3.90:0.10:0.80:0.10:   0:0.80:0.20:0.20:   0:0.60:0.10:   0:0.70:0.10:0.10:0.30:0.10
03-01 15:06:22|  0   0 100   0   0|4769M  492M   22M   14G|   0    72k|   0  28.0 |   0:0.10:   0:   0:0.10:   0:0.30:0.30:   0:   0:0.10:   0:   0:0.10:0.10:   0:0.10
03-01 15:06:23|  0   0 100   0   0|4766M  496M   22M   14G|   0  8193B|   0  2.00 |   0:   0:   0:   0:   0:   0:   0:   0:   0:   0:   0:   0:   0:   0:   0:   0:   0

```

---

## Command 10: mpstat

### Command
```bash
mpstat -P ALL 1 70
```

### Output
```
Linux 6.14.0-1018-aws (ip-10-0-1-227) 	01/03/26 	_aarch64_	(8 CPU)

15:06:18     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
15:06:19     all    0.50    0.00    0.25    1.00    0.00    0.00    0.00    0.00    0.00   98.25
15:06:19       0    0.00    0.00    0.00    2.00    0.00    0.00    0.00    0.00    0.00   98.00
15:06:19       1    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:19       2    0.00    0.00    0.99    0.99    0.00    0.00    0.00    0.00    0.00   98.02
15:06:19       3    0.00    0.00    0.00    1.00    0.00    0.00    0.00    0.00    0.00   99.00
15:06:19       4    3.00    0.00    1.00    1.00    0.00    0.00    0.00    0.00    0.00   95.00
15:06:19       5    0.99    0.00    0.00    2.97    0.00    0.00    0.00    0.00    0.00   96.04
15:06:19       6    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:19       7    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00

15:06:19     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
15:06:20     all    0.00    0.00    0.25    0.38    0.00    0.00    0.00    0.00    0.00   99.38
15:06:20       0    0.00    0.00    1.00    0.00    0.00    0.00    0.00    0.00    0.00   99.00
15:06:20       1    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:20       2    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:20       3    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:20       4    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:20       5    0.00    0.00    1.00    3.00    0.00    0.00    0.00    0.00    0.00   96.00
15:06:20       6    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:20       7    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00

15:06:20     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
15:06:21     all    0.38    0.00    0.12    0.38    0.00    0.00    0.00    0.00    0.00   99.12
15:06:21       0    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:21       1    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:21       2    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:21       3    2.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00   98.00
15:06:21       4    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:21       5    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:21       6    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:21       7    0.99    0.00    0.99    2.97    0.00    0.00    0.00    0.00    0.00   95.05

15:06:21     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
15:06:22     all    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:22       0    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:22       1    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:22       2    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:22       3    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:22       4    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:22       5    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:22       6    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
15:06:22       7    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00

```

---

## Command 11: pg_wait_events

### Command
```bash
bash -c while true; do date '+%H:%M:%S'; sudo -u postgres psql -c "SELECT wait_event_type, wait_event, count(*) FROM pg_stat_activity WHERE state = 'active' GROUP BY 1, 2 ORDER BY 3 DESC LIMIT 10;"; sleep 1; done
```

### Output
```
No output
```

---

## Command 12: pg_checkpoint_log

### Command
```bash
bash -c timeout 70s tail -f /var/log/postgresql/postgresql-16-main.log 2>/dev/null | grep -i checkpoint || true
```

### Output
```

```

---

## Command 13: End:pg_stat_bgwriter

### Command
```bash
sudo -u postgres psql -c SELECT buffers_checkpoint AS "Checkpoints Wrote", buffers_clean AS "BgWriter Wrote", buffers_backend AS "Backends Wrote (BAD!)", buffers_alloc AS "Total Allocated" FROM pg_stat_bgwriter;
```

### Output
```
psql: warning: extra command-line argument "Checkpoints Wrote," ignored
psql: warning: extra command-line argument "buffers_clean" ignored
psql: warning: extra command-line argument "AS" ignored
psql: warning: extra command-line argument "BgWriter Wrote," ignored
psql: warning: extra command-line argument "buffers_backend" ignored
psql: warning: extra command-line argument "AS" ignored
psql: warning: extra command-line argument "Backends Wrote (BAD!)," ignored
psql: warning: extra command-line argument "buffers_alloc" ignored
psql: warning: extra command-line argument "AS" ignored
psql: warning: extra command-line argument "Total Allocated" ignored
psql: warning: extra command-line argument "FROM" ignored
psql: warning: extra command-line argument "pg_stat_bgwriter" ignored
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "AS"

```

---
