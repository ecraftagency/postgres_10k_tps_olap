# Disk Benchmark Guide

Hướng dẫn benchmark storage cho **fresh OS + RAID setup** trước khi cài đặt database.

---

## 1. Mục tiêu Benchmark

```
┌─────────────────────────────────────────────────────────────────┐
│                    BENCHMARK OBJECTIVES                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   1. Xác định giới hạn vật lý (ceiling) của storage            │
│   2. Verify RAID configuration hoạt động đúng                  │
│   3. Thu thập baseline metrics trước khi cài database          │
│   4. Phát hiện bottleneck hoặc misconfiguration                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Storage Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         EC2 Instance                            │
│                    (c8g.2xlarge - 8 vCPU)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────────────────┐     ┌─────────────────────────┐  │
│   │      DATA Volume        │     │       WAL Volume        │  │
│   │      /dev/md0           │     │       /dev/md1          │  │
│   │      Mount: /data       │     │       Mount: /wal       │  │
│   ├─────────────────────────┤     ├─────────────────────────┤  │
│   │  RAID10 (8 disks)       │     │  RAID10 (8 disks)       │  │
│   │  Chunk: 64KB            │     │  Chunk: 256KB           │  │
│   │  Usable: 200GB          │     │  Usable: 120GB          │  │
│   │  Purpose: Random I/O    │     │  Purpose: Sequential    │  │
│   └─────────────────────────┘     └─────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Theoretical Limits (RAID10 8×gp3)

| Metric | Formula | Value |
|--------|---------|-------|
| **Read IOPS** | 8 × 3000 | 24,000 |
| **Write IOPS** | 4 × 3000 | 12,000 |
| **Throughput** | 4 × 125 MB/s | 500 MB/s |
| **QD1 Sync IOPS** | 1000 / latency_ms | ~540 |

---

## 3. Benchmark Scenarios (10 Tests)

### 3.1 Overview

| # | Volume | Name | Pattern | Đo gì? |
|---|--------|------|---------|--------|
| 1 | WAL | Sync Latency | QD1 + fsync | Min latency per sync |
| 5 | WAL | Sequential Write | QD16 async | Max write bandwidth |
| 6 | WAL | Concurrent Sync | QD32×4 + fsync | Max sync IOPS |
| 10 | WAL | Sequential Read | QD8 | Max read bandwidth |
| 2 | DATA | Mixed Stress | QD64×4, R70:W30 | Max IOPS under load |
| 3 | DATA | Random Read Latency | QD1 | True storage latency |
| 4 | DATA | Sequential Read | QD16 | Max read bandwidth |
| 7 | DATA | Sequential Write | QD16 | Max write bandwidth |
| 8 | DATA | Random Write | QD64×4 | Max write IOPS |
| 9 | DATA | Mixed + Sync | QD32×4 + fsync | Realistic sync I/O |

---

## 4. WAL Volume Benchmarks

### Scenario 1: Sync Latency (The Heartbeat)

**Mục đích**: Đo latency tối thiểu của 1 sync write - "speed of light" của storage.

```bash
fio --name=sync_latency \
    --filename=/wal/bench_sync \
    --size=2G \
    --time_based --runtime=60s \
    --ioengine=libaio \
    --direct=1 \
    --bs=8k \
    --rw=write \
    --fdatasync=1 \
    --iodepth=1 \
    --numjobs=1 \
    --group_reporting
```

| Parameter | Value | Lý do |
|-----------|-------|-------|
| `bs=8k` | 8KB | Small write |
| `fdatasync=1` | Sync mỗi write | Đo true sync latency |
| `iodepth=1` | QD1 | No queueing |
| `numjobs=1` | Single thread | Isolate latency |

**Target Metrics:**
| Metric | Target | Measured |
|--------|--------|----------|
| IOPS | ~540 | **536** |
| Latency (avg) | <2ms | **1.858ms** |
| Latency (p99) | <3ms | **2.5ms** |

---

### Scenario 5: Sequential Write Bandwidth (The Firehose)

**Mục đích**: Đo max write bandwidth - giới hạn throughput.

```bash
fio --name=seq_write_bw \
    --filename=/wal/bench_seqw \
    --size=5G \
    --time_based --runtime=60s \
    --ioengine=libaio \
    --direct=1 \
    --bs=1M \
    --rw=write \
    --iodepth=16 \
    --numjobs=1 \
    --group_reporting
```

| Parameter | Value | Lý do |
|-----------|-------|-------|
| `bs=1M` | 1MB | Large block cho throughput |
| `iodepth=16` | QD16 | Saturate bandwidth |
| No fdatasync | Async | Pure throughput test |

**Target Metrics:**
| Metric | Target | Measured |
|--------|--------|----------|
| Bandwidth | ~500 MB/s | **508 MB/s** |
| IOPS | ~500 | **508** |

---

### Scenario 6: Concurrent Sync IOPS (The Traffic Jam)

**Mục đích**: Đo max sync IOPS với nhiều concurrent writers.

```bash
fio --name=concurrent_sync \
    --filename=/wal/bench_conc \
    --size=5G \
    --time_based --runtime=60s \
    --ioengine=libaio \
    --direct=1 \
    --bs=32k \
    --rw=write \
    --fdatasync=1 \
    --iodepth=32 \
    --numjobs=4 \
    --group_reporting
```

| Parameter | Value | Lý do |
|-----------|-------|-------|
| `bs=32k` | 32KB | Batched writes |
| `fdatasync=1` | Sync | With durability |
| `iodepth=32` | QD32 | Queue depth per job |
| `numjobs=4` | 4 threads | Concurrent writers |

**Target Metrics:**
| Metric | Target | Measured |
|--------|--------|----------|
| IOPS | ~16,000 | **16,200** |
| Bandwidth | ~500 MB/s | **505 MB/s** |

---

### Scenario 10: Sequential Read Bandwidth (Recovery Replay)

**Mục đích**: Đo max read bandwidth - quan trọng cho recovery.

```bash
fio --name=seq_read_bw \
    --filename=/wal/bench_seqr \
    --size=5G \
    --time_based --runtime=60s \
    --ioengine=libaio \
    --direct=1 \
    --bs=1M \
    --rw=read \
    --iodepth=8 \
    --numjobs=1 \
    --group_reporting
```

**Target Metrics:**
| Metric | Target | Measured |
|--------|--------|----------|
| Bandwidth | ~1000 MB/s | **1,003 MB/s** |

---

## 5. DATA Volume Benchmarks

### Scenario 2: Mixed IOPS Stress Test

**Mục đích**: Đo max IOPS với mixed read/write workload.

```bash
fio --name=mixed_stress \
    --filename=/data/bench_stress \
    --size=5G \
    --time_based --runtime=60s \
    --ioengine=libaio \
    --direct=1 \
    --bs=8k \
    --rw=randrw \
    --rwmixread=70 \
    --iodepth=64 \
    --numjobs=4 \
    --group_reporting
```

| Parameter | Value | Lý do |
|-----------|-------|-------|
| `bs=8k` | 8KB | Small random I/O |
| `rwmixread=70` | 70% read | Typical OLTP ratio |
| `iodepth=64` | QD64 | High queue depth |
| `numjobs=4` | 4 threads | 256 total concurrent |

**Target Metrics:**
| Metric | Target | Measured |
|--------|--------|----------|
| Read IOPS | ~13,000 | **13,100** |
| Write IOPS | ~5,500 | **5,600** |
| Total IOPS | ~18,500 | **18,700** |

---

### Scenario 3: Random Read Latency

**Mục đích**: Đo true storage latency - "speed of light" cho reads.

```bash
fio --name=rand_read_lat \
    --filename=/data/bench_lat \
    --size=5G \
    --time_based --runtime=60s \
    --ioengine=libaio \
    --direct=1 \
    --bs=8k \
    --rw=randread \
    --iodepth=1 \
    --numjobs=1 \
    --group_reporting
```

**Target Metrics:**
| Metric | Target | Measured |
|--------|--------|----------|
| IOPS | ~1,700 | **1,690** |
| Latency (avg) | <1ms | **0.589ms** |
| Latency (p99) | <1.5ms | **1.06ms** |

---

### Scenario 4: Sequential Read Bandwidth

**Mục đích**: Đo max read bandwidth cho sequential scan.

```bash
fio --name=seq_read_bw \
    --filename=/data/bench_seqr \
    --size=5G \
    --time_based --runtime=60s \
    --ioengine=libaio \
    --direct=1 \
    --bs=1M \
    --rw=read \
    --iodepth=16 \
    --numjobs=1 \
    --group_reporting
```

**Target Metrics:**
| Metric | Target | Measured |
|--------|--------|----------|
| Bandwidth | ~1000 MB/s | **1,003 MB/s** |
| Latency (avg) | <20ms | **15.96ms** |

---

### Scenario 7: Sequential Write Bandwidth

**Mục đích**: Đo max write bandwidth.

```bash
fio --name=seq_write_bw \
    --filename=/data/bench_seqw \
    --size=5G \
    --time_based --runtime=60s \
    --ioengine=libaio \
    --direct=1 \
    --bs=1M \
    --rw=write \
    --iodepth=16 \
    --numjobs=1 \
    --group_reporting
```

**Target Metrics:**
| Metric | Target | Measured |
|--------|--------|----------|
| Bandwidth | ~500 MB/s | **509 MB/s** |

---

### Scenario 8: Random Write IOPS

**Mục đích**: Đo max random write IOPS.

```bash
fio --name=rand_write \
    --filename=/data/bench_randw \
    --size=5G \
    --time_based --runtime=60s \
    --ioengine=libaio \
    --direct=1 \
    --bs=8k \
    --rw=randwrite \
    --iodepth=64 \
    --numjobs=4 \
    --group_reporting
```

**Target Metrics:**
| Metric | Target | Measured |
|--------|--------|----------|
| IOPS | ~12,000 | **12,200** |
| Bandwidth | ~95 MB/s | **95.1 MB/s** |

---

### Scenario 9: Mixed with Sync (DB-Realistic)

**Mục đích**: Đo IOPS với sync writes - gần với DB thực tế.

```bash
fio --name=mixed_sync \
    --filename=/data/bench_sync \
    --size=5G \
    --time_based --runtime=60s \
    --ioengine=libaio \
    --direct=1 \
    --bs=8k \
    --rw=randrw \
    --rwmixread=70 \
    --fdatasync=1 \
    --iodepth=32 \
    --numjobs=4 \
    --group_reporting
```

**Target Metrics:**
| Metric | Target | Measured |
|--------|--------|----------|
| Read IOPS | ~13,000 | **13,100** |
| Write IOPS | ~5,500 | **5,600** |

---

## 6. Benchmark Strategy

### 6.1 Execution Order

```
┌─────────────────────────────────────────────────────────────────┐
│                    BENCHMARK EXECUTION ORDER                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Phase 1: Latency Tests (Establish baseline)                  │
│   ─────────────────────────────────────────────                │
│   1. Scenario 1: WAL Sync Latency     → T_sync baseline        │
│   2. Scenario 3: DATA Random Latency  → T_read baseline        │
│                                                                 │
│   Phase 2: Bandwidth Tests (Verify throughput ceiling)         │
│   ─────────────────────────────────────────────────            │
│   3. Scenario 4: DATA Seq Read        → Read BW ceiling        │
│   4. Scenario 5: WAL Seq Write        → Write BW ceiling       │
│   5. Scenario 7: DATA Seq Write       → Verify write BW        │
│   6. Scenario 10: WAL Seq Read        → Verify read BW         │
│                                                                 │
│   Phase 3: IOPS Tests (Verify IOPS ceiling)                    │
│   ──────────────────────────────────────────                   │
│   7. Scenario 2: DATA Mixed Stress    → Mixed IOPS ceiling     │
│   8. Scenario 8: DATA Random Write    → Write IOPS ceiling     │
│   9. Scenario 6: WAL Concurrent Sync  → Sync IOPS ceiling      │
│                                                                 │
│   Phase 4: Realistic Tests (Verify real-world behavior)        │
│   ───────────────────────────────────────────────────          │
│   10. Scenario 9: DATA Mixed Sync     → DB-realistic IOPS      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 Pre-Benchmark Checklist

```bash
# 1. Verify RAID status
cat /proc/mdstat
sudo mdadm --detail /dev/md0
sudo mdadm --detail /dev/md1

# 2. Verify mount options
mount | grep -E "md0|md1"

# 3. Verify block device tuning
cat /sys/block/md0/queue/read_ahead_kb    # Should be 64
cat /sys/block/md1/queue/read_ahead_kb    # Should be 4096

# 4. Verify XFS alignment
xfs_info /data
xfs_info /wal

# 5. Check for existing I/O
iostat -x 1 3
```

### 6.3 During Benchmark Monitoring

```bash
# Terminal 1: Run benchmark
sudo python3 ~/scripts/bench.py --run <N>

# Terminal 2: Monitor I/O
iostat -x 1

# Terminal 3: Monitor dirty pages
watch -n 1 'grep -E "Dirty|Writeback" /proc/meminfo'
```

---

## 7. Results Summary

### 7.1 Measured Results (8×gp3 RAID10)

| # | Scenario | Key Metric | Measured | vs Target |
|---|----------|------------|----------|-----------|
| 1 | Sync Latency | Latency | **1.858ms** | ✓ |
| 3 | Random Read | Latency | **0.589ms** | ✓ |
| 4 | Seq Read | Bandwidth | **1,003 MB/s** | ✓ |
| 5 | Seq Write | Bandwidth | **508 MB/s** | ✓ |
| 7 | Seq Write | Bandwidth | **509 MB/s** | ✓ |
| 10 | Seq Read | Bandwidth | **1,003 MB/s** | ✓ |
| 2 | Mixed Stress | IOPS | **18,700** | ✓ |
| 8 | Random Write | IOPS | **12,200** | ✓ |
| 6 | Concurrent Sync | IOPS | **16,200** | ✓ |
| 9 | Mixed Sync | IOPS | **18,700** | ✓ |

### 7.2 Key Numbers to Remember

```
┌─────────────────────────────────────────────────────────────────┐
│                    STORAGE CEILING SUMMARY                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   LATENCY (Speed of Light)                                     │
│   ────────────────────────                                     │
│   Sync Write:  1.858 ms  → Max 538 sync/sec single-thread      │
│   Random Read: 0.589 ms  → Max 1,700 IOPS single-thread        │
│                                                                 │
│   BANDWIDTH                                                     │
│   ─────────                                                     │
│   Sequential Read:  1,003 MB/s  (exceeds 500MB/s theoretical)  │
│   Sequential Write: 509 MB/s    (matches theoretical)          │
│                                                                 │
│   IOPS                                                          │
│   ────                                                          │
│   Mixed (70R:30W):  18,700 IOPS (Read 13.1K + Write 5.6K)     │
│   Random Write:     12,200 IOPS (matches 4×3000 theoretical)  │
│   Concurrent Sync:  16,200 IOPS                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. Troubleshooting

### 8.1 Low IOPS

```bash
# Check RAID status
cat /proc/mdstat  # Should show [UUUUUUUU]

# Check if disks are throttled
dmesg | grep -i throttl

# Check EBS burst balance
aws cloudwatch get-metric-statistics ...
```

### 8.2 High Latency

```bash
# Check queue depth
cat /sys/block/nvme*/queue/nr_requests

# Check for I/O wait
iostat -x 1 | grep await

# Check dirty pages
grep -E "Dirty|Writeback" /proc/meminfo
```

### 8.3 Low Bandwidth

```bash
# Check read_ahead setting
cat /sys/block/md*/queue/read_ahead_kb

# Verify XFS alignment
xfs_info /data | grep sunit
```

---

## 9. Running Benchmarks

### Using bench.py

```bash
# Run individual scenario
sudo python3 ~/scripts/bench.py --run 1   # Sync Latency
sudo python3 ~/scripts/bench.py --run 2   # Mixed Stress
# ... etc

# Run all disk benchmarks (1-10, excluding 11 which is PostgreSQL)
for i in 1 2 3 4 5 6 7 8 9 10; do
    sudo python3 ~/scripts/bench.py --run $i
    sleep 5
done
```

### Output Location

```
~/scripts/results/
├── wal_heartbeat_report_*.md       # Scenario 1
├── data_stress_report_*.md         # Scenario 2
├── data_latency_report_*.md        # Scenario 3
├── data_throughput_report_*.md     # Scenario 4
├── wal_firehose_report_*.md        # Scenario 5
├── wal_trafficjam_report_*.md      # Scenario 6
├── data_seq_write_report_*.md      # Scenario 7
├── data_rand_write_report_*.md     # Scenario 8
├── data_mixed_sync_report_*.md     # Scenario 9
└── wal_replay_report_*.md          # Scenario 10
```

---

## 10. EBS gp3 Reference

### Per-Disk Specs

| Metric | Value |
|--------|-------|
| Baseline IOPS | 3,000 |
| Baseline Throughput | 125 MB/s |
| Latency | 1.5-2.5 ms |
| Burst | Credit-based |

### RAID10 Calculations

```
Read IOPS  = N_disks × IOPS_per_disk = 8 × 3000 = 24,000
Write IOPS = N_stripes × IOPS_per_disk = 4 × 3000 = 12,000
Throughput = N_stripes × BW_per_disk = 4 × 125 = 500 MB/s

QD1 Sync IOPS = 1000ms / latency_ms = 1000 / 1.858 = 538
```
