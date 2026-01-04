# Benchmark: [POSTGRES DISK] High Concurrency Locking - 1000 Clients fighting for resources

**Date:** 2026-01-04 10:11:43
**Scenario:** 1000 Clients fighting for resources

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

Linux ip-10-0-1-39 6.14.0-1018-aws #18~24.04.1-Ubuntu SMP Mon Nov 24 19:32:52 UTC 2025 aarch64 aarch64 aarch64 GNU/Linux
Architecture:                            aarch64
CPU(s):                                  8
Model name:                              Neoverse-V2
total        used        free      shared  buff/cache   available
Mem:            15Gi       518Mi        14Gi       1.1Mi       1.0Gi        14Gi
Swap:             0B          0B          0B

=== OS TUNING ===
vm.swappiness = 60
vm.dirty_ratio = 20
vm.dirty_background_ratio = 10
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
always [madvise] never

=== NETWORK ===
net.core.somaxconn = 4096
net.core.rmem_max = 212992
net.core.wmem_max = 212992
net.ipv4.tcp_tw_reuse = 2
net.ipv4.tcp_fin_timeout = 60

=== DISK - RAID ===
Personalities : 
unused devices: <none>



=== DISK - BLOCK TUNING ===
--- md0 ---
scheduler: 
read_ahead_kb: 
nr_requests: 
--- md1 ---
scheduler: 
read_ahead_kb: 
nr_requests: 

=== DISK - MOUNT ===



=== DISK - XFS ===


```

---

## Command 1: Begin:pg_stat_reset

### Command
```bash
psql -h localhost -p 5432 -U postgres -c pgbench
```

### Output
```
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  No pool configured for database: "postgres", user: "postgres"

```

---

## Command 2: pgbench

### Command
```bash
pgbench -h localhost -p 5432 -U postgres -c 1000 -j 32 -T 60 -P 5 pgbench
```

### Output
```
pgbench (16.11 (Ubuntu 16.11-0ubuntu0.24.04.1))
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1250
query mode: simple
number of clients: 1000
number of threads: 32
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 1244710
number of failed transactions: 0 (0.000%)
latency average = 48.162 ms
latency stddev = 15.550 ms
initial connection time = 73.279 ms
tps = 20754.280217 (without initial connection time)
starting vacuum...end.
progress: 5.0 s, 19883.0 tps, lat 49.295 ms stddev 19.781, 0 failed
progress: 10.0 s, 20824.3 tps, lat 48.028 ms stddev 14.942, 0 failed
progress: 15.0 s, 20841.1 tps, lat 47.936 ms stddev 15.149, 0 failed
progress: 20.0 s, 20840.1 tps, lat 48.003 ms stddev 15.005, 0 failed
progress: 25.0 s, 20761.9 tps, lat 48.180 ms stddev 15.228, 0 failed
progress: 30.0 s, 20795.6 tps, lat 48.090 ms stddev 15.246, 0 failed
progress: 35.0 s, 20830.4 tps, lat 48.016 ms stddev 15.256, 0 failed
progress: 40.0 s, 20801.5 tps, lat 48.053 ms stddev 15.030, 0 failed
progress: 45.0 s, 20840.5 tps, lat 47.974 ms stddev 15.044, 0 failed
progress: 50.0 s, 20840.6 tps, lat 47.989 ms stddev 15.052, 0 failed
progress: 55.0 s, 20737.6 tps, lat 48.213 ms stddev 15.311, 0 failed
progress: 60.0 s, 20751.7 tps, lat 48.175 ms stddev 15.101, 0 failed

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
 4  0      0 14685160  45860 1020184    0    0    64   102 2333    3  0  0 99  0  0  0
 0  0      0 14684120  45860 1020264    0    0     0     0  409  183  1  0 99  0  0  0
 2  0      0 14679584  45860 1020264    0    0     0     0  358  173  0  0 100  0  0  0
14  0      0 14613248  45860 1022168    0    0     0     0 232578 199887 37 45 19  0  0  0
 8  0      0 14607908  45860 1022360    0    0     0     0 283465 249776 34 58  8  0  0  0
10  0      0 14600880  45860 1022368    0    0     0     0 282579 250587 34 59  7  0  0  0
16  0      0 14595416  45860 1022420    0    0     0     0 283354 249093 33 59  7  0  0  0
13  0      0 14594336  45860 1022420    0    0     0     0 281430 252130 35 58  7  0  0  0
18  0      0 14590132  45860 1022424    0    0     0     0 276172 247582 34 59  7  0  0  0
 7  0      0 14590272  45860 1022424    0    0     0     0 277867 247856 34 59  7  0  0  0
13  0      0 14586604  45860 1022460    0    0     0   244 268128 246333 33 59  8  0  0  0
14  0      0 14581820  45860 1022464    0    0     0     0 267967 244064 34 58  9  0  0  0
 7  0      0 14583452  45860 1022464    0    0     0     0 274132 245703 34 58  8  0  0  0
14  0      0 14583532  45860 1022464    0    0     0     0 282243 249335 33 60  7  0  0  0
15  0      0 14586588  45860 1022464    0    0     0     0 270232 247373 35 58  7  0  0  0
19  0      0 14589388  45860 1022496    0    0     0     0 271296 246446 35 58  7  0  0  0
17  0      0 14590472  45860 1022500    0    0     0     0 269585 246236 35 58  7  0  0  0
 8  0      0 14589372  45860 1022504    0    0     0     0 268506 246409 34 58  8  0  0  0
10  0      0 14585140  45860 1022508    0    0     0     0 265093 246761 34 58  7  0  0  0
18  0      0 14586676  45860 1022508    0    0     0     0 268461 245087 34 59  8  0  0  0
14  0      0 14585728  45860 1022508    0    0     0     0 262778 247128 33 60  7  0  0  0
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
12  0      0 14582952  45860 1022512    0    0     0     0 260383 244702 33 61  7  0  0  0
21  0      0 14584712  45860 1022516    0    0     0     0 253832 246017 35 58  7  0  0  0
17  0      0 14581884  45868 1022508    0    0     0    76 257172 247435 33 61  6  0  0  0
11  0      0 14578244  45868 1022520    0    0     0    56 272029 246123 33 58  8  0  0  0
13  0      0 14579008  45868 1022520    0    0     0     0 264681 247112 34 59  7  0  0  0
10  0      0 14578412  45868 1022520    0    0     0     0 273672 245745 34 59  7  0  0  0
13  0      0 14577408  45868 1022520    0    0     0     0 254367 245945 34 58  7  0  0  0
13  0      0 14578636  45868 1022520    0    0     0     0 254635 249404 34 60  6  0  0  0
12  0      0 14579568  45868 1022524    0    0     0     0 252601 248648 34 60  6  0  0  0
11  1      0 14580432  45868 1022524    0    0     0  2400 254730 249329 33 61  6  0  0  0
14  0      0 14579712  45868 1022524    0    0     0   144 255943 243445 33 60  7  0  0  0
10  0      0 14580252  45868 1022524    0    0     0     0 263198 247513 34 60  6  0  0  0
13  0      0 14579504  45868 1022524    0    0     0     0 252384 247767 34 60  7  0  0  0
16  0      0 14580292  45868 1022524    0    0     0     0 261144 248893 35 59  6  0  0  0
18  0      0 14580396  45868 1022532    0    0     0     0 266333 245351 34 59  7  0  0  0
15  0      0 14580724  45868 1022532    0    0     0     0 269659 245593 34 59  8  0  0  0
12  0      0 14580144  45868 1022532    0    0     0     0 271540 246044 33 59  8  0  0  0
10  0      0 14583708  45868 1022532    0    0     0     0 265121 247824 34 59  7  0  0  0
11  0      0 14579252  45868 1022532    0    0     0     0 263638 246444 33 59  7  0  0  0
 3  0      0 14579376  45868 1022532    0    0     0     0 259541 247150 34 59  7  0  0  0
 8  0      0 14575744  45868 1022536    0    0     0     0 269874 243352 34 58  8  0  0  0
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
17  0      0 14574412  45868 1022544    0    0     0     0 266250 247233 34 59  7  0  0  0
16  0      0 14581464  45868 1022544    0    0     0     0 269274 245197 34 59  8  0  0  0
13  0      0 14576772  45868 1022544    0    0     0     0 271568 246218 33 60  7  0  0  0
 6  0      0 14578332  45868 1022544    0    0     0     0 279192 245565 34 59  7  0  0  0
 9  0      0 14578232  45868 1022548    0    0     0     0 261738 246168 34 60  6  0  0  0
15  0      0 14578888  45868 1022548    0    0     0     0 259797 244652 31 61  8  0  0  0
 2  0      0 14579776  45868 1022548    0    0     0     0 259483 245986 34 59  7  0  0  0
21  0      0 14580248  45868 1022552    0    0     0     0 261114 246806 34 59  7  0  0  0
 9  0      0 14582000  45868 1022552    0    0     0     0 266717 247087 34 59  7  0  0  0
11  0      0 14580844  45868 1022552    0    0     0     0 272388 246038 34 60  7  0  0  0
17  0      0 14581292  45868 1022556    0    0     0     0 268902 249097 34 60  6  0  0  0
 9  0      0 14580944  45876 1022548    0    0     0    52 261511 247724 34 59  7  0  0  0
 2  0      0 14582160  45876 1022556    0    0     0     0 270548 249458 32 59  8  0  0  0
18  0      0 14580676  45876 1022556    0    0     0     0 273479 246259 34 58  8  0  0  0
12  0      0 14580140  45876 1022556    0    0     0     0 281993 244901 35 58  8  0  0  0
15  0      0 14580200  45876 1022556    0    0     0     0 278836 249046 33 59  8  0  0  0
18  0      0 14582100  45876 1022556    0    0     0     0 271633 245874 33 59  8  0  0  0
 4  0      0 14578348  45876 1022560    0    0     0     0 270123 247546 34 60  6  0  0  0
14  0      0 14575936  45876 1022560    0    0     0     0 254280 247020 34 60  6  0  0  0
16  0      0 14575664  45876 1022560    0    0     0   872 264806 248168 34 60  6  0  0  0
15  0      0 14577724  45876 1022560    0    0     0    16 260819 246532 33 57 10  0  0  0
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 0  0      0 14663828  45876 1021588    0    0     0     0 16297 16043  2  4 94  0  0  0
 0  0      0 14662844  45876 1021588    0    0     0     0  345  185  0  0 100  0  0  0

```

---

## Command 4: pg_wait_events

### Command
```bash
bash -c 'for i in $(seq 1 70); do echo "=== $(date '"'"'+%H:%M:%S'"'"') ==="; sudo -u postgres psql -t -c "SELECT coalesce(wait_event_type,'"'"'CPU'"'"') as type, coalesce(wait_event,'"'"'Running'"'"') as event, count(*) as cnt FROM pg_stat_activity WHERE state='"'"'active'"'"' AND pid<>pg_backend_pid() GROUP BY 1,2 ORDER BY 3 DESC LIMIT 5"; sleep 1; done'
```

### Output
```
=== 10:10:39 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:40 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:41 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:42 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:43 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:44 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:45 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:46 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:47 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:48 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:49 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:50 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:51 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:52 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:53 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:55 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:56 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:57 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:58 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:10:59 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:00 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:01 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:02 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:03 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:04 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:05 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:06 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:07 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:08 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:09 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:10 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:11 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:12 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:13 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:14 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:15 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:16 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:17 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:18 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:19 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:20 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:22 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:23 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:24 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:25 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:26 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:27 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:28 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:29 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:30 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:31 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:32 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:33 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:34 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:35 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:36 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:37 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:38 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:39 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:40 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:41 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:11:42 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?

```

---

## Command 5: pg_deep_stats

### Command
```bash
bash -c 'echo '"'"'Time,Active,WaitLock,Deadlock'"'"'; for i in $(seq 1 12); do sudo -u postgres psql -t -A -F'"'"','"'"' -c "SELECT to_char(now(), '"'"'HH24:MI:SS'"'"'), (SELECT count(*) FROM pg_stat_activity WHERE state='"'"'active'"'"'), (SELECT count(*) FROM pg_stat_activity WHERE wait_event_type='"'"'Lock'"'"'), d.deadlocks FROM pg_stat_database d WHERE d.datname = current_database()"; sleep 5; done'
```

### Output
```
Time,Active,WaitLock,Deadlock
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?

```

---
