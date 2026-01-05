# Quick Start Guide

Get a PostgreSQL benchmark running in under 15 minutes.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- SSH key pair created in AWS

## Step 1: Deploy Infrastructure

```bash
# Clone and navigate to terraform
cd terraform/topologies/single-node

# Initialize terraform
terraform init

# Deploy with r8g.2xlarge (8 vCPU, 64GB RAM)
terraform apply \
  -var="aws_profile=your-aws-profile" \
  -var="key_name=your-key-name" \
  -var="postgres_ami=ami-0266f4b9e2c1841fb" \
  -var-file=../../hardware/r8g.2xlarge.tfvars

# Note the output IP address
export IP=$(terraform output -raw postgres_public_ip)
```

## Step 2: Sync Scripts to Server

```bash
# From project root
rsync -avz -e "ssh -i ~/.ssh/your-key.pem" \
  scripts2/ ubuntu@$IP:~/scripts2/
```

## Step 3: Server Setup

SSH into the server and run setup scripts:

```bash
ssh -i ~/.ssh/your-key.pem ubuntu@$IP

# Install dependencies
sudo ./scripts2/setup/00-deps.sh

# Configure OS tuning (sysctl, limits, hugepages)
sudo ./scripts2/setup/01-os-tuning.sh

# Setup RAID10 arrays (DATA + WAL)
sudo ./scripts2/setup/02-raid-setup.sh

# Configure disk tuning (read_ahead, scheduler)
sudo ./scripts2/setup/03-disk-tuning.sh

# Install PostgreSQL 16
sudo ./scripts2/postgres/install.sh

# Configure PostgreSQL for TPC-B workload
sudo ./scripts2/postgres/configure.sh --hardware r8g.2xlarge --workload tpc-b

# Initialize pgbench database (scale factor from config)
sudo -u postgres pgbench -i -s 1000 postgres
```

## Step 4: Run Benchmark

```bash
# Run TPC-B benchmark (60 seconds, 100 clients)
sudo python3 scripts2/core/bench.py \
  --topology single-node \
  --hardware r8g.2xlarge \
  --workload tpc-b \
  --duration 60 \
  --clients 100
```

Expected output:
```
============================================================
BENCHMARK: single-node/r8g.2xlarge--tpc-b
============================================================
Context: single-node/r8g.2xlarge--tpc-b
Duration: 60s, Clients: 100

--- Config Verification ---
  PostgreSQL: 12 checks passed
  OS: 5 checks passed
  Disk: 4 checks passed

--- Warmup Phase ---
  Running 30s warmup...

--- Benchmark Phase (60s) ---
  Running TPC-B benchmark...

============================================================
BENCHMARK RESULTS
============================================================

  19,554 TPS | 5.11ms avg latency | P99: 12.45ms

Report saved: results/single-node/r8g.2xlarge--tpc-b/tpc-b_20260105-103045.md
```

## Step 5: Retrieve Results

```bash
# From local machine
rsync -avz -e "ssh -i ~/.ssh/your-key.pem" \
  ubuntu@$IP:~/scripts2/results/ scripts2/results/
```

## Step 6: Cleanup

```bash
# Destroy infrastructure when done
cd terraform/topologies/single-node
terraform destroy
```

## Common Options

### Different Hardware

```bash
# Smaller instance (4 vCPU, 32GB RAM)
terraform apply -var-file=../../hardware/r8g.xlarge.tfvars

# Larger instance (16 vCPU, 128GB RAM)
terraform apply -var-file=../../hardware/r8g.4xlarge.tfvars
```

### Different Topologies

```bash
# With connection pooling (PgCat)
cd terraform/topologies/proxy-single
terraform apply -var-file=../../hardware/r8g.2xlarge.tfvars

# With replication
cd terraform/topologies/primary-replica
terraform apply -var-file=../../hardware/r8g.2xlarge.tfvars
```

### Benchmark Options

```bash
# Longer duration
sudo python3 scripts2/core/bench.py -L single-node -H r8g.2xlarge -W tpc-b \
  --duration 300 --clients 200

# Skip warmup
sudo python3 scripts2/core/bench.py -L single-node -H r8g.2xlarge -W tpc-b \
  --no-warmup

# Skip AI analysis
sudo python3 scripts2/core/bench.py -L single-node -H r8g.2xlarge -W tpc-b \
  --skip-ai

# Skip config verification
sudo python3 scripts2/core/bench.py -L single-node -H r8g.2xlarge -W tpc-b \
  --skip-verify

# Diagnostics only (no benchmark)
sudo python3 scripts2/core/bench.py -L single-node -H r8g.2xlarge -W tpc-b \
  --diagnostics-only
```

## Troubleshooting

### Terraform fails to create resources

Check AWS credentials:
```bash
aws sts get-caller-identity --profile your-profile
```

### SSH connection refused

Wait for instance to fully boot:
```bash
aws ec2 wait instance-status-ok --instance-ids i-xxx
```

### PostgreSQL won't start

Check hugepages allocation:
```bash
cat /proc/meminfo | grep Huge
# HugePages_Total should match vm.nr_hugepages in config
```

### Low TPS results

1. Verify config: `sudo python3 scripts2/core/bench.py ... --skip-verify` shows warnings
2. Check disk setup: `lsblk` should show md0, md1 RAID arrays
3. Check PostgreSQL logs: `journalctl -u postgresql@16-main`

## Next Steps

- [Benchmarking Guide](BENCHMARKING.md) - Advanced benchmark options
- [Configuration Reference](CONFIGURATION.md) - All parameters explained
- [Tuning Guide](TUNING.md) - Mathematical rationale for settings
