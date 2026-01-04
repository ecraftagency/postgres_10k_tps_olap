# Benchmark: [POSTGRES DISK] Connection Storm - Tests authentication overhead (connect per transaction)

**Date:** 2026-01-04 10:07:52
**Scenario:** Tests authentication overhead (connect per transaction)

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
Mem:            15Gi       551Mi        13Gi       1.1Mi       1.0Gi        14Gi
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

## Command 1: pgbench

### Command
```bash
pgbench -h localhost -p 5432 -U postgres -S -C -c 50 -j 8 -T 60 -P 5 pgbench
```

### Output
```
pgbench (16.11 (Ubuntu 16.11-0ubuntu0.24.04.1))
transaction type: <builtin: select only>
scaling factor: 1250
query mode: simple
number of clients: 50
number of threads: 8
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 841198
number of failed transactions: 0 (0.000%)
latency average = 1.889 ms
latency stddev = 1.338 ms
average connection time = 0.560 ms
tps = 14019.728799 (including reconnection times)
starting vacuum...end.
progress: 5.0 s, 14719.5 tps, lat 1.812 ms stddev 1.782, 0 failed
progress: 10.0 s, 14460.7 tps, lat 1.838 ms stddev 1.610, 0 failed
progress: 15.0 s, 13828.8 tps, lat 1.919 ms stddev 1.539, 0 failed
progress: 20.0 s, 13853.4 tps, lat 1.918 ms stddev 1.353, 0 failed
progress: 25.0 s, 13843.4 tps, lat 1.904 ms stddev 1.259, 0 failed
progress: 30.0 s, 13912.2 tps, lat 1.902 ms stddev 1.196, 0 failed
progress: 35.0 s, 14007.2 tps, lat 1.887 ms stddev 1.164, 0 failed
progress: 40.0 s, 14065.6 tps, lat 1.883 ms stddev 1.156, 0 failed
progress: 45.0 s, 13855.9 tps, lat 1.912 ms stddev 1.182, 0 failed
progress: 50.0 s, 13746.9 tps, lat 1.918 ms stddev 1.202, 0 failed
progress: 55.0 s, 13868.8 tps, lat 1.903 ms stddev 1.203, 0 failed
progress: 60.0 s, 14071.8 tps, lat 1.879 ms stddev 1.182, 0 failed

```

---

## Command 2: dstat_tcp

### Command
```bash
dstat -tn 1 70
```

### Output
```
/bin/sh: 1: dstat: not found

```

---

## Command 3: pg_conn_stats

### Command
```bash
bash -c 'for i in $(seq 1 12); do echo "=== $(date '"'"'+%H:%M:%S'"'"') ==="; sudo -u postgres psql -t -c "SELECT state, count(*) FROM pg_stat_activity GROUP BY 1 ORDER BY 2 DESC"; sleep 5; done'
```

### Output
```
=== 10:06:48 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:06:53 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:06:58 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:07:03 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:07:08 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:07:13 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:07:18 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:07:23 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:07:28 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:07:33 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:07:39 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
=== 10:07:44 ===
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?

```

---
