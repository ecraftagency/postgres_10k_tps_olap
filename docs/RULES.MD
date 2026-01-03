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

## 4. Config Separation
- **Tất cả config name/value phải nằm ở file external**
- `config.env`: OS/RAID/XFS config (shell-compatible KEY=VALUE)
- `infra.toml`: Hardware specs, dynamic ceilings (TOML format)
- Script chỉ chứa logic, không chứa hardcoded values
- Shell scripts: `source config.env`
- Python scripts: load cả `config.env` và `infra.toml`

```
scripts/
├── config.env          # OS/RAID/XFS config
├── infra.toml          # Hardware specs (dynamic ceilings)
├── 01-os-tuning.sh     # source config.env rồi execute
├── 02-raid-setup.sh
├── 04-benchmark.py     # load config.env + infra.toml
└── bench/              # Python benchmark package
```

## 5. UI/UX
- **Không sử dụng command line flags** - user dễ quên, khó dùng
- TUI (Terminal UI) cho user interaction: pick scenario, confirm action
- Config values đọc từ file, không expose ra CLI

## 6. Task Tracking
- Phase = chủ đề lớn (provisioning, installation, configuration)
- Task = bước nhỏ trong phase
- File `TASKS.MD` để theo dõi tiến độ
