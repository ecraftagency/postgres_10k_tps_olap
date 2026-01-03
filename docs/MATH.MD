# MATH.MD: Nền tảng Toán học của High-Performance I/O Systems

**Scope:** PostgreSQL, Kafka, Distributed Storage (MinIO, Cassandra, etc.)
**Environment:** AWS c8g.2xlarge (8 vCPU, 16GB RAM) + 16× EBS gp3 RAID10

> **Nguyên tắc cốt lõi:** Tuning không phải nghệ thuật hay may mắn. Nó là **Toán học chính xác**.
>
> - **Hardware** cung cấp giới hạn trần (Max IOPS, Min Latency)
> - **OS** đảm bảo đường ống I/O không bị tắc
> - **Application** điều chỉnh hành vi (Batching, Cleaning) để khớp với giới hạn phần cứng

---

## 1. HARDWARE & PROVISIONING (Giới hạn vật lý)

Mục này tính toán **giới hạn trần** mà không phần mềm nào có thể vượt qua.

### 1.1 The "Speed of Light" Limit (Network Latency)

Trong môi trường Cloud Storage như EBS, đĩa nằm **qua mạng**. Mỗi I/O operation phải đi qua:

$$T_{total} = T_{network} + T_{media} + T_{queue}$$

**Benchmark FIO của hệ thống (QD1):**

| Operation | Measured | Benchmark |
|-----------|----------|-----------|
| $T_{sync\_write}$ | **1.858 ms** | wal_heartbeat (fdatasync) |
| $T_{random\_read}$ | **0.589 ms** | data_latency |

**Ứng dụng cho PostgreSQL:**

Nếu `synchronous_commit = on`, mỗi COMMIT cần 1 fsync:

$$TPS_{max\_serial} = \frac{1000 \text{ ms}}{T_{sync}} = \frac{1000}{1.858} = 538 \text{ TPS}$$

✓ **Verification:** Benchmark wal_heartbeat đo được **536 IOPS**

**Ứng dụng cho Kafka/Streaming:**

Nếu `acks=all`, Latency của 1 message tối thiểu là:

$$Lat_{kafka} = T_{sync} + T_{network\_repl} \approx 1.858 \text{ ms} + \delta$$

Với 3 brokers replication, $\delta$ có thể +1-2ms → **Latency tối thiểu ~3-4ms/message**

**Kết luận:** Để đạt throughput cao, phải **bypass** latency này bằng **batching**.

---

### 1.2 Little's Law for Disk (Throughput Formula)

Để đạt băng thông lớn trên đường truyền có độ trễ cao, cần **Queue Depth** đủ lớn.

**Định luật Little:**

$$QD = Throughput \times Latency$$

Hoặc đảo ngược:

$$Throughput = \frac{QD}{Latency}$$

**Tính toán Queue Depth cần thiết:**

Hệ thống c8g.2xlarge có EBS bandwidth tối đa ~1,250 MB/s. Với block size 1MB và latency 15.96ms (từ benchmark):

$$IOPS_{required} = \frac{1,250 \text{ MB/s}}{1 \text{ MB}} = 1,250 \text{ IOPS}$$

$$QD_{required} = 1,250 \times 0.01596 = 19.95 \approx 20$$

✓ **Verification:** Benchmark data_throughput với QD=16 đạt 1,003 MB/s (80% max)

**Ứng dụng cho PostgreSQL:**

```
effective_io_concurrency = 200
```

Con số 200 **dư sức** vì RAID10 8 disks có thể xử lý nhiều parallel I/O.

**Ứng dụng cho Kafka:**

```properties
num.replica.fetchers = 4
num.io.threads = 8
```

Phải đủ lớn để tạo ra queue depth ≥20 cho throughput tối đa.

---

### 1.3 RAID10 Performance Math

**Raw Capacity:** 8 đĩa gp3 × 2 volumes (DATA + WAL)

**Read Performance (Theoretical):**

$$IOPS_{read} = \sum_{i=1}^{N} IOPS_{disk\_i} = 8 \times 3,000 = 24,000$$

**Write Performance (Write Penalty):**

Với RAID10, mỗi logical write sinh ra 2 physical writes (mirror):

$$IOPS_{write\_logical} = \frac{\sum IOPS_{disk}}{2} = \frac{24,000}{2} = 12,000$$

**Throughput:**

$$BW_{max} = N_{stripes} \times BW_{disk} = 4 \times 125 = 500 \text{ MB/s}$$

**So sánh Lý thuyết vs Thực tế:**

| Metric | Formula | Lý thuyết | Đo được | Hiệu suất |
|--------|---------|-----------|---------|-----------|
| Read IOPS | $8 \times 3000$ | 24,000 | 13,100 | 55% |
| Write IOPS | $4 \times 3000$ | 12,000 | **12,200** | **102%** |
| Seq Read BW | $4 \times 125$ | 500 MB/s | **1,003 MB/s** | **201%** |
| Seq Write BW | $4 \times 125$ | 500 MB/s | **509 MB/s** | **102%** |

**Tại sao >100%?** EBS gp3 có **burst credits** cho phép vượt baseline ngắn hạn.

---

## 2. OS / DISK LAYOUT (The Pipeline Efficiency)

Tối ưu để dòng dữ liệu chảy qua các tầng (OS → FS → RAID) không bị **tắc nghẽn**.

### 2.1 The "Split I/O" Avoidance (Công thức Alignment)

**Mục tiêu:** 1 Logical I/O **không bao giờ** bị xé thành 2 Physical I/O.

**Điều kiện an toàn:**

$$BlockSize \le ChunkSize$$

$$\text{VÀ } (Address_{start} \mod ChunkSize) + BlockSize \le ChunkSize$$

**PostgreSQL:**

- Block Size = 8 KB (page size)
- Chunk Size = 64 KB

$$8 \text{ KB} \ll 64 \text{ KB} \rightarrow \textbf{SAFE}$$

Mỗi PostgreSQL page nằm gọn trong 1 chunk, không bao giờ bị split.

**Kafka/Streaming:**

Kafka thường ghi log segment lớn (batch). Nếu:
- Batch size = 128 KB
- Chunk size = 64 KB

$$128 \text{ KB} > 64 \text{ KB} \rightarrow \textbf{LUÔN BỊ SPLIT!}$$

1 write đánh vào 2 đĩa → 2x latency, throughput giảm 50%.

**Tối ưu cho Kafka:**

$$ChunkSize \ge MaxBatchSize$$

Ví dụ: `batch.size = 128KB` → Chunk nên ≥ 256KB

**Đó là lý do WAL disk dùng Chunk 256KB** (ghi tuần tự, batch lớn).

**Minh họa:**

```
PostgreSQL DATA (Chunk = 64KB):
┌────────────────────────────────────────────────────────────────┐
│  Chunk 64KB                                                     │
│  ┌────┬────┬────┬────┬────┬────┬────┬────┐                     │
│  │8KB │8KB │8KB │8KB │8KB │8KB │8KB │8KB │  ← 8 PG pages       │
│  │ ██ │    │    │    │    │    │    │    │  ← 1 write nằm gọn  │
│  └────┴────┴────┴────┴────┴────┴────┴────┘                     │
└────────────────────────────────────────────────────────────────┘

Kafka với Chunk quá nhỏ (64KB < 128KB batch):
┌────────────────────────────────────────────────────────────────┐
│  1 write 128KB bị XÉ thành 2 physical writes:                  │
│  ┌────────────────┐  ┌────────────────┐                        │
│  │    Chunk 1     │  │    Chunk 2     │                        │
│  │  ████ (64KB)   │  │  ████ (64KB)   │                        │
│  └────────────────┘  └────────────────┘                        │
│                                                                 │
│  → 2x latency, throughput giảm 50%                             │
└────────────────────────────────────────────────────────────────┘
```

---

### 2.2 Dirty Ratio Calculation (Công thức "Chống Lag")

**Mục tiêu:** Thời gian xả RAM (Flush) **không được gây treo hệ thống** quá 1 giây.

**Công thức:**

$$M_{dirty} = V_{disk} \times T_{stall}$$

$$Dirty\_Ratio = \frac{M_{dirty}}{M_{total}} \times 100$$

**Tính toán cụ thể:**

| Variable | Value | Source |
|----------|-------|--------|
| $V_{disk}$ (Max Write Speed) | 509 MB/s | Benchmark data_seq_write |
| $T_{stall}$ (Max acceptable) | 1 second | Target |
| $M_{total}$ (System RAM) | 16,384 MB | c8g.2xlarge |

$$M_{dirty} = 509 \text{ MB/s} \times 1\text{s} = 509 \text{ MB}$$

$$Dirty\_Ratio = \frac{509}{16,384} \times 100 = 3.1\%$$

$\rightarrow$ **Chọn `vm.dirty_ratio = 4%`** (có buffer margin)

$\rightarrow$ **Chọn `vm.dirty_background_ratio = 1%`** (bắt đầu flush sớm ở ~160MB)

**Verification:**
- dirty_ratio = 4% → Max dirty = 655 MB
- Flush time = 655 MB ÷ 509 MB/s = **1.29s** → Acceptable

**Hậu quả nếu dùng default (10%):**

$$Flush\_Time = \frac{1,638 \text{ MB}}{509 \text{ MB/s}} = 3.2 \text{ giây} \rightarrow \textbf{I/O Cliff nghiêm trọng!}$$

---

## 3. POSTGRES CONFIGURATION (The Tuning Logic)

Chứng minh các con số config bằng toán học.

### 3.1 BgWriter Tuning (Công thức "Dọn Rác")

**Bài toán:** Backend sinh dirty pages với tốc độ $V_{dirty}$. BgWriter phải dọn với tốc độ $V_{clean} \ge V_{dirty}$.

**Công thức BgWriter capacity:**

$$V_{clean} = \frac{bgwriter\_lru\_maxpages \times 8 \text{ KB}}{bgwriter\_delay}$$

**Ước tính $V_{dirty}$ từ Benchmark:**

- TPS đạt được: 11,500
- Giả sử 10% là Write mới (Insert/Update)
- Mỗi write ~1 dirty page

$$V_{dirty} \approx 11,500 \times 0.10 = 1,150 \text{ pages/s} \approx 9 \text{ MB/s}$$

**Phân tích Default Config:**

| Parameter | Default |
|-----------|---------|
| bgwriter_delay | 200 ms |
| bgwriter_lru_maxpages | 100 pages |

$$V_{clean\_default} = \frac{100 \text{ pages}}{0.2 \text{s}} = 500 \text{ pages/s} \approx 4 \text{ MB/s}$$

$$4 \text{ MB/s} < 9 \text{ MB/s} \rightarrow \textbf{FAIL!}$$

**Hậu quả:** Backend phải tự ghi dirty pages → **Backend Write Storm** → TPS drop.

**Tuned Config:**

| Parameter | Tuned |
|-----------|-------|
| bgwriter_delay | **10 ms** |
| bgwriter_lru_maxpages | **1000 pages** |

$$V_{clean\_tuned} = \frac{1000 \text{ pages}}{0.01 \text{s}} = 100,000 \text{ pages/s} \approx 800 \text{ MB/s}$$

$$800 \text{ MB/s} \gg 9 \text{ MB/s} \rightarrow \textbf{PASS!}$$

Dư sức dọn dẹp, **luôn có clean pages sẵn**.

**Benchmark Verification:**

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| buffers_clean | 31,359 | **126,564** | **+304%** |
| TPS | 9,912 | **11,469** | **+16%** |

---

### 3.2 Checkpoint Spread (Công thức "Làm phẳng I/O")

**Mục tiêu:** Checkpoint không gây I/O spike.

**Công thức:**

$$Rate_{avg} = \frac{max\_wal\_size}{checkpoint\_timeout}$$

$$Rate_{peak} = \frac{max\_wal\_size}{checkpoint\_timeout \times completion\_target}$$

**Tính toán:**

| Parameter | Value |
|-----------|-------|
| max_wal_size | 48 GB |
| checkpoint_timeout | 30 min = 1800 s |
| completion_target | 0.9 |

$$Rate_{avg} = \frac{48,000 \text{ MB}}{1800 \text{ s}} = 26.6 \text{ MB/s}$$

$$Rate_{peak} = \frac{48,000 \text{ MB}}{1800 \times 0.9} = \frac{48,000}{1620} = 29.6 \text{ MB/s}$$

**So sánh với năng lực đĩa:**

$$\frac{29.6 \text{ MB/s}}{509 \text{ MB/s}} = 5.8\% \rightarrow \textbf{Checkpoint rất êm ái}$$

Không gây I/O Spike vì chỉ dùng **5.8% disk capacity**.

---

### 3.3 Group Commit Efficiency (Công thức "Bypass fsync")

**Bài toán:** Làm sao đạt 11,500 TPS khi sync latency = 1.858 ms?

**Không có batching:**

$$TPS_{serial} = \frac{1000}{T_{sync}} = \frac{1000}{1.858} = 538 \text{ TPS}$$

**Với batching (N transactions per sync):**

$$TPS_{total} = \frac{N_{batch}}{T_{sync}} \times 1000$$

**Tính batch factor từ Benchmark:**

$$N_{batch} = \frac{TPS \times T_{sync}}{1000} = \frac{11,469 \times 1.858}{1000} = 21.3$$

**Insight:** Mỗi lần fsync gom được **~21 transactions**!

**Config `commit_delay = 50µs`:**

Thời gian chờ 50µs rất nhỏ so với 1858µs (latency), nhưng đủ để các process khác kịp gửi request vào hàng đợi.

$$Overhead = \frac{50}{1858} = 2.7\% \text{ latency increase}$$

Đây là **đòn bẩy hiệu năng** (Leverage) - đánh đổi 2.7% latency để tăng throughput 21x.

**Minh họa:**

```
WITHOUT Group Commit (mỗi TX 1 fsync):
───────────────────────────────────────
TX1: COMMIT ───► fsync (1.8ms) ───► Done
TX2:     COMMIT ───► fsync (1.8ms) ───► Done
TX3:         COMMIT ───► fsync (1.8ms) ───► Done

Max: 538 TPS (bị giới hạn bởi latency)

WITH Group Commit (gom 21 TX / 1 fsync):
────────────────────────────────────────
TX1-21: COMMIT ─┬─► (wait 50µs) ─► fsync (1.8ms) ─► All Done
                │
                └─► 21 transactions committed in 1.85ms
                    Effective: 0.088ms per commit (21x faster!)
```

---

## 4. TPS & LATENCY ANALYSIS (The Correlation)

### 4.1 Max Serial TPS Formula (Định luật Amdahl cho Transaction)

Nếu chạy 1 client đơn luồng (như Kafka Producer `acks=all`, 1 thread):

$$TPS_{serial} = \frac{1}{T_{sync} + T_{process}}$$

Với $T_{sync} = 1.858 \text{ ms}$, $T_{process} \approx 0$:

$$TPS_{max\_serial} = \frac{1000}{1.858} \approx 538 \text{ TPS}$$

**Ứng dụng:**

| System | Single-thread Max | Cách bypass |
|--------|-------------------|-------------|
| PostgreSQL | 538 TPS | Group Commit |
| Kafka (acks=all) | ~540 msg/s | Batching (linger.ms) |
| Redis (AOF fsync) | ~540 ops/s | appendfsync everysec |

---

### 4.2 IOPS to TPS Conversion (Công thức quy đổi)

**Công thức:**

$$TPS = \frac{IOPS_{available}}{IOPS_{per\_transaction}}$$

**TPC-B Transaction I/O Cost:**

| Operation | IOPS Cost |
|-----------|-----------|
| 1 SELECT | 0-1 read |
| 3 UPDATEs | 0-3 reads |
| 1 INSERT | 0 (append) |
| 1 COMMIT | 1/21 sync (group commit) |
| **Total** | ~1.6 IOPS/TX (sau buffering) |

**Prediction:**

$$TPS_{predicted} = \frac{IOPS_{max}}{Cost_{per\_tx}} = \frac{18,700}{1.6} = 11,687$$

$$TPS_{actual} = 11,469$$

$$Error = \frac{|11,687 - 11,469|}{11,469} = 1.9\%$$

**Ý nghĩa:** Khi hệ thống được tune chuẩn, **TPS tỷ lệ thuận tuyến tính với IOPS** của đĩa. Công thức này cho phép dự đoán TPS từ benchmark disk!

---

### 4.3 Connection Pool Sizing

**Công thức:**

$$N_{connections} = TPS_{target} \times T_{transaction}$$

**Tính toán:**

$$N_{connections} = 11,500 \times 0.00870 = 100.05 \approx 100$$

✓ **Verification:** Benchmark dùng **100 clients** → Matches!

**Headroom cho complex queries:**

Nếu $T_{transaction}$ = 30 ms:

$$N_{connections} = 11,500 \times 0.030 = 345$$

$\rightarrow$ Chọn **max_connections = 300** (với margin)

---

### 4.4 Connection Overhead (Chi phí Forking)

Từ benchmark "Connection Storm" (`-C` reconnect per transaction):

| Metric | Persistent | Reconnect (`-C`) |
|--------|------------|------------------|
| TPS | 12,331 | 1,704 |
| Drop | - | **-86%** |

**Công thức chi phí kết nối ($T_{connect}$):**

$$T_{tx} = \frac{1}{TPS_{persistent}} = \frac{1}{12,331} = 0.081 \text{ ms}$$

$$T_{total} = \frac{1}{TPS_{reconnect}} = \frac{1}{1,704} = 0.587 \text{ ms}$$

$$T_{connect} = T_{total} - T_{tx} = 0.587 - 0.081 = 0.506 \text{ ms}$$

**Phân tích:**

```
Thời gian 1 Transaction với Reconnect:
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   Query Execution:     0.08 ms  ████                                │
│   Connection Setup:    0.51 ms  ██████████████████████████████      │
│                        ──────                                       │
│   Total:               0.59 ms                                      │
│                                                                     │
│   → Connection costs 6.3× more than the actual query!              │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Công thức TPS với Connection Pool:**

$$TPS_{pooled} = \frac{1}{T_{tx}} = \frac{1}{0.081} = 12,345$$

$$TPS_{no\_pool} = \frac{1}{T_{tx} + T_{connect}} = \frac{1}{0.587} = 1,704$$

$$Efficiency_{pool} = \frac{TPS_{pooled}}{TPS_{no\_pool}} = \frac{12,345}{1,704} = 7.2\times$$

**Kết luận:**
- Connection setup tốn **0.5 ms** CPU System time
- Gấp **6.3 lần** thời gian thực thi query
- Connection Pooling tăng throughput **7.2×**
- $\rightarrow$ **Luôn dùng PgBouncer hoặc Connection Pool**

---

## 5. COST ANALYSIS (Economic Math)

### 5.1 Cost per TPS

**Công thức:**

$$Cost\_per\_TPS = \frac{Monthly\_Cost}{TPS}$$

$$Cost\_per\_Million\_TX = \frac{Monthly\_Cost}{TPS \times 86400 \times 30}$$

**Hệ thống hiện tại (On-Demand):**

| Component | Cost/Month |
|-----------|------------|
| EC2 c8g.2xlarge | $208.08 |
| EBS DATA (8×50GB gp3) | $25.60 |
| EBS WAL (8×30GB gp3) | $15.36 |
| **Total** | **$249.04** |

$$Cost\_per\_TPS = \frac{249.04}{11,469} = \$0.0217/TPS/month$$

$$Monthly\_TX = 11,469 \times 60 \times 60 \times 24 \times 30 = 29.7 \text{ billion}$$

$$Cost\_per\_Million = \frac{249.04}{29,700} = \$0.0084/million$$

### 5.2 Horizontal vs Vertical (io2 Block Express)

**io2 Block Express cho performance tương đương:**

| Requirement | Cost |
|-------------|------|
| IOPS: 20,000 | $0.046 × 20,000 = $920 |
| Storage: 660 GB | $0.125 × 660 = $82.50 |
| **Total** | **$1,002.50/month** |

**So sánh:**

| Metric | io2 Block Express | RAID10 gp3 | Tiết kiệm |
|--------|-------------------|------------|-----------|
| Monthly Cost | $1,002.50 | $249.04 | **75%** |
| Cost (Spot) | $1,002.50 | $103.60 | **90%** |

**Break-even:**

$$Payback = \frac{Setup\_Cost}{Monthly\_Savings} = \frac{1,500}{753} = 2.0 \text{ months}$$

---

## 6. BENCHMARK DATA SUMMARY

### 6.1 Disk I/O (FIO)

| Scenario | Key Metric | Measured |
|----------|------------|----------|
| **wal_heartbeat** (QD1+fsync) | Sync Latency | **1.858 ms** |
| **wal_heartbeat** | Sync IOPS | **536** |
| **wal_trafficjam** (QD32×4+fsync) | Group IOPS | **16,200** |
| **wal_firehose** (QD16 seq) | Write BW | **508 MB/s** |
| **data_latency** (QD1 random) | Read Latency | **0.589 ms** |
| **data_stress** (QD64×4 mixed) | Total IOPS | **18,700** |
| **data_throughput** (QD16 seq) | Read BW | **1,003 MB/s** |
| **data_rand_write** (QD64×4) | Write IOPS | **12,200** |

### 6.2 PostgreSQL (pgbench TPC-B)

| Phase | TPS | Latency | buffers_clean |
|-------|-----|---------|---------------|
| Baseline | ~7,000 | ~15 ms | Low |
| OS Tuned | 9,912 | 10.05 ms | 31,359 |
| **PG Tuned** | **11,469** | **8.70 ms** | **126,564** |

---

## 7. FORMULA CHEAT SHEET

### Hardware Limits
```
TPS_max_serial = 1000 / T_sync_ms
QD = IOPS × Latency_sec
Write_IOPS_RAID10 = (N_disks / 2) × IOPS_per_disk
```

### OS Tuning
```
dirty_ratio = (V_disk × T_stall) / RAM × 100
ChunkSize ≥ MaxBlockSize (để tránh Split I/O)
```

### PostgreSQL
```
V_clean = (maxpages × 8KB) / delay_sec
N_batch = TPS × T_sync / 1000
N_connections = TPS × T_tx_avg
Checkpoint_Rate = max_wal_size / (timeout × completion_target)
```

### Prediction
```
TPS_predicted = IOPS_max / IOPS_per_tx
Cost_per_TPS = Monthly_cost / TPS
```

---

## 8. SUMMARY

File này chứng minh rằng **Tuning = Toán học chính xác**:

| Layer | Công thức | Kết quả |
|-------|-----------|---------|
| **Hardware** | $TPS_{serial} = 1000/T_{sync}$ | Max 538 TPS single-thread |
| **OS** | $Dirty\_Ratio = V_{disk} \times T_{stall} / RAM$ | 4% (không phải 10% default) |
| **PostgreSQL** | $V_{clean} = maxpages / delay$ | 800 MB/s >> 9 MB/s dirty rate |
| **Group Commit** | $N_{batch} = TPS \times T_{sync} / 1000$ | 21 TX/sync → bypass latency |
| **Prediction** | $TPS = IOPS / Cost_{per\_tx}$ | 11,687 predicted ≈ 11,469 actual (1.9% error) |

> **"Every config value has a mathematical justification."**
>
> Nếu không thể derive từ formulas và measurements, bạn đang guessing - và guessing không scale.
