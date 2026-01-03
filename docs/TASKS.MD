# DANH SÁCH CÔNG VIỆC

## Phase 1: Provisioning PostgreSQL Instance

### 1.1 Terraform Infrastructure
- [ ] VPC + Public Subnet
- [ ] Security Group (port 22)
- [ ] Spot Instance Request (c8gb.2xlarge)
- [ ] EBS Volumes: 8x50GB (data), 8x30GB (wal)
- [ ] Volume attachments
- [ ] `terraform apply` thành công

### 1.2 OS Tuning
- [ ] Script: `01-os-tuning.sh`
- [ ] Memory params (vm.*)
- [ ] File descriptors (fs.*, ulimits)
- [ ] TCP stack tuning
- [ ] Disable THP
- [ ] Xác nhận: `cat /proc/sys/vm/swappiness` = 1

### 1.3 RAID Setup
- [ ] Script: `02-raid-setup.sh`
- [ ] Đợi đủ 16 disks
- [ ] Tạo RAID10 md0 (data): chunk=64K (tối ưu random I/O)
- [ ] Tạo RAID10 md1 (wal): chunk=256K (tối ưu sequential)
- [ ] Format XFS với alignment phù hợp
- [ ] Mount với options tối ưu
- [ ] Xác nhận: `cat /proc/mdstat`

### 1.4 Disk I/O Tuning
- [ ] Script: `03-disk-tuning.sh`
- [ ] Block device tuning cho DATA disks
- [ ] Block device tuning cho WAL disks
- [ ] MD device tuning (stripe_cache_size)
- [ ] Udev rules cho persistence
- [ ] Xác nhận: `cat /sys/block/md0/queue/read_ahead_kb`

### 1.5 Disk Benchmark (Python)
- [ ] Python package: `bench/` - Real-time benchmark suite
  - [ ] `04-benchmark.py` - TUI wrapper script
  - [ ] `bench/cli.py` - Interactive TUI (scenario selection)
  - [ ] `bench/config.py` - Load config.env + infra.toml
  - [ ] `bench/metrics.py` - 40+ metric definitions
  - [ ] `bench/collector.py` - fio/iostat/vmstat collectors
  - [ ] `bench/display.py` - Rich real-time tables
  - [ ] `bench/runner.py` - Test orchestration
  - [ ] `bench/export.py` - JSON/CSV/HTML export
  - [ ] `bench/schema.py` - Structured output schema
  - [ ] `bench/sysconfig.py` - Collect actual system config
  - [ ] `bench/ai_evaluator.py` - Gemini AI evaluation
- [ ] Chạy: `./04-benchmark.py` (TUI - không có command line flags)
- [ ] Xác nhận:
  - [ ] DATA: Read ≥15K IOPS, Write ≥10K IOPS
  - [ ] WAL: Seq8K ≥1.2K IOPS (EBS latency bound)
  - [ ] Jitter (p99-p95) ≤ 2ms
  - [ ] No bottlenecks detected

---

## Phase 2: PostgreSQL Installation
- [x] Script: `05-db-install.sh` (idempotent, reads from config.env)
- [x] PostgreSQL 16 configuration (34 settings)
- [x] pgbench initialization (scale=1250, ~18GB data)
- [x] Benchmark: pgbench TPC-B (scenario 11)
  - [x] 9,500-11,000 TPS (peak 15K)
  - [x] I/O cliff observed during checkpoint
- [x] AMI snapshot: `ami-0b309fbbb037a3166`

---

## Phase 3: PgCat Node
- [ ] Terraform: PgCat instance
- [ ] Script: PgCat install + config

---

## Phase 4: RisingWave Node
- [ ] Terraform: RisingWave instance + RAID0 volumes
- [ ] Script: RAID0 setup (2x128GB)
- [ ] Script: RisingWave install

---

## Phase 5: Integration
- [ ] PgCat -> PostgreSQL connectivity
- [ ] RisingWave CDC từ PostgreSQL
- [ ] End-to-end benchmark

---

## Scripts Hiện Tại

### Configuration Files

| File | Mục đích | Trạng thái |
|------|----------|------------|
| `config.env` | OS/RAID/XFS/PostgreSQL config | Hoàn thành |
| `scenarios.json` | Benchmark scenarios (11 scenarios) | Hoàn thành |

### Shell Scripts (Setup & Tuning)

| File | Mục đích | Trạng thái |
|------|----------|------------|
| `01-os-tuning.sh` | Kernel params, THP, ulimits | Hoàn thành |
| `02-raid-setup.sh` | RAID10 + XFS format + mount | Hoàn thành |
| `03-disk-tuning.sh` | Block device tuning | Hoàn thành |
| `05-db-install.sh` | PostgreSQL 16 + pgbench init | Hoàn thành |
| `deps.sh` | Install benchmark dependencies | Hoàn thành |

### Python Scripts (Benchmark)

| File | Mục đích | Trạng thái |
|------|----------|------------|
| `bench.py` | Unified benchmark tool (fio + pgbench) | Hoàn thành |

### Benchmark Features

- **11 Scenarios**: 10 fio (disk) + 1 pgbench (PostgreSQL)
- **3-Phase Structure**: begin/parallel/end
- **Monitoring**: iostat, mpstat, dstat, meminfo, pg_wait_events
- **AI Analysis**: Gemini API integration (optional)
- **Export**: Markdown reports with full command output

## Documentation

| File | Mục đích | Trạng thái |
|------|----------|------------|
| `INFRA.MD` | Kiến trúc hệ thống | Hoàn thành |
| `SYSTEM_CONFIG.MD` | OS + Disk I/O tuning strategy | Cập nhật |
| `DB_CONFIG.MD` | PostgreSQL configuration | Hoàn thành |
| `DISK_BENCHMARK.MD` | Disk benchmark (fio, 10 scenarios) | Hoàn thành |
| `POSTGRES_BENCHMARK.MD` | PostgreSQL benchmark (pgbench) | Hoàn thành |
| `RULES.MD` | Golden rules | Hoàn thành |
| `TASKS.MD` | Danh sách công việc | Cập nhật |
