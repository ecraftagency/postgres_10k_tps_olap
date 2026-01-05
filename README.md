# PostgreSQL Benchmark Framework

High-performance PostgreSQL benchmarking on AWS with EBS gp3 RAID10.

**Latest Results:** 19,554 TPS on r8g.2xlarge ($290/mo) - see [results](scripts2/results/)

## What This Is

A complete framework for:
- **Infrastructure as Code** - Terraform modules for different topologies
- **Automated Benchmarking** - Python framework with TPC-B/C/H workloads
- **Config Verification** - Ensure settings match expectations before benchmarking
- **Rich Reporting** - Markdown reports with AI analysis

## Quick Start

```bash
# 1. Deploy infrastructure
cd terraform/topologies/single-node
terraform apply -var-file=../../hardware/r8g.2xlarge.tfvars

# 2. Sync scripts to server
rsync -avz scripts2/ ubuntu@<IP>:~/scripts2/

# 3. Run benchmark
ssh ubuntu@<IP>
sudo python3 scripts2/core/bench.py -L single-node -H r8g.2xlarge -W tpc-b
```

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/ARCHITECTURE.md) | System design, directory structure, context naming |
| [Quick Start](docs/QUICKSTART.md) | Step-by-step setup guide |
| [Benchmarking](docs/BENCHMARKING.md) | Running benchmarks, interpreting results |
| [Configuration](docs/CONFIGURATION.md) | All parameters reference |
| [Tuning](docs/TUNING.md) | Mathematical rationale for every setting |
| [Terraform](terraform/README.md) | Infrastructure deployment guide |

## Project Structure

```
.
├── terraform/
│   ├── modules/           # Reusable: network, security, postgres-node, pgcat-node
│   ├── topologies/        # single-node, proxy-single, primary-replica
│   └── hardware/          # r8g.xlarge.tfvars, r8g.2xlarge.tfvars, ...
│
├── scripts2/
│   ├── core/              # bench.py, reporter.py, config_loader.py
│   ├── drivers/           # pgbench, hammerdb, fio
│   ├── hardware/          # r8g.xlarge/, r8g.2xlarge/ (hardware.env)
│   ├── workloads/         # tpc-b/, tpc-c/, tpc-h/ (tuning.env)
│   ├── setup/             # OS tuning, RAID setup
│   └── results/           # Benchmark reports
│
└── docs/                  # Documentation
```

## Context Naming

Three-dimensional context: `{topology}/{hardware}--{workload}`

```
single-node/r8g.2xlarge--tpc-b
proxy-single/r8g.4xlarge--tpc-c
primary-replica/r8g.2xlarge--tpc-h
```

## Requirements

- AWS Account with EC2/EBS access
- Terraform >= 1.0
- Python 3.8+
- Ubuntu 24.04 LTS (ARM64)

## License

MIT
