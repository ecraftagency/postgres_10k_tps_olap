# GOLDEN RULES

## 1. Pace
- Đi chậm, nhận thức kỹ từng bước
- Chia nhỏ vấn đề: do one thing and do it well

## 2. Layered Deployment
Triển khai và kiểm định theo tầng:
```
hardware → os config → disk config → disk benchmark → software install → software config → verify
```

## 3. Script Standards
- Không comment dư thừa trong code
- Mỗi script làm 1 việc duy nhất
- **Idempotent end-to-end**: chạy lại từ đầu phải trở về đúng trạng thái mong muốn, bất kể trạng thái hiện tại

## 4. Config Separation (Hardware Context System)
- **Tất cả config name/value phải nằm ở file external**
- Config organized by hardware context: `scripts/hardware/<context>/`
- Context naming: `<instance_type>.<net_gbps>.<ebs_gbps>.<disk_count>disk.<raid_level>`
- Shell scripts: `source load-config.sh` (auto-loads from hardware context)

```
scripts/
├── hardware/
│   ├── _template/              # Config template
│   ├── generate-config.sh      # Generate config for new hardware
│   └── c8gb.2xlarge.33.25.8disk.raid10/
│       ├── config.env          # OS/RAID/XFS/PostgreSQL tuning
│       ├── proxy/pgcat.toml    # PgCat configuration
│       ├── topology.yaml       # Infrastructure spec
│       └── TUNING_NOTES.md     # Tuning rationale
├── load-config.sh              # Config loader
├── 01-os-tuning.sh             # source load-config.sh
├── 02-raid-setup.sh
├── 03-disk-tuning.sh
├── 05-db-install.sh
└── bench.py                    # Unified benchmark tool
```

### Parameter Classification
| Type | Example | Source |
|------|---------|--------|
| Calculated | `shared_buffers = 25% RAM` | Hardware specs |
| Experience-tuned | `bgwriter_delay = 10ms` | Benchmarking |

## 5. UI/UX
- **Không sử dụng command line flags** - user dễ quên, khó dùng
- TUI (Terminal UI) cho user interaction: pick scenario, confirm action
- Config values đọc từ file, không expose ra CLI

## 6. Task Tracking
- Phase = chủ đề lớn (provisioning, installation, configuration)
- Task = bước nhỏ trong phase
- File `TASKS.MD` để theo dõi tiến độ
