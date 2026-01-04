# Infrastructure Configuration

## CRITICAL RULES
1. **Instance Types**: DO NOT suggest alternatives even on quota errors - user decides
2. **DB AMI**: MUST restore from AMI, never install from scratch
3. **AWS Profile**: Always use `boxloop-admin`
4. **SSH Key**: Use `~/.ssh/id_rsa` (not terraform key_name .pem file)

## AWS Configuration
| Setting | Value |
|---------|-------|
| Profile | `boxloop-admin` |
| Region | `us-west-2` |
| AZ | `us-west-2a` |

## AMI Configuration
| Component | AMI ID | Description |
|-----------|--------|-------------|
| DB | `ami-0266f4b9e2c1841fb` | PostgreSQL 16 + 16 EBS volumes (RAID10) + configured |
| Proxy | `ami-01efdecff661a215d` | PgCat 1.3.0 pre-installed |

**IMPORTANT**: DB AMI includes all EBS volumes from snapshots. Do NOT create separate EBS volumes in terraform.

---

## Hardware Context System

Configuration is organized by hardware context - a unique identifier that captures the full infrastructure topology.

### Naming Convention
```
<instance_type>.<net_gbps>.<ebs_gbps>.<disk_count>disk.<raid_level>
```

Example: `c8gb.2xlarge.33.25.8disk.raid10`
- `c8gb.2xlarge` - AWS instance type (Graviton4, block optimized)
- `33` - Network bandwidth (33 Gbps)
- `25` - EBS bandwidth (25 Gbps)
- `8disk` - 8 EBS volumes per RAID array
- `raid10` - RAID level

### Directory Structure
```
scripts/
├── hardware/
│   ├── _template/
│   │   └── config.env.template
│   ├── generate-config.sh
│   └── c8gb.2xlarge.33.25.8disk.raid10/
│       ├── config.env          # DB + OS tuning parameters
│       ├── proxy/
│       │   └── pgcat.toml      # PgCat configuration
│       ├── topology.yaml       # Infrastructure topology
│       ├── TUNING_NOTES.md     # Tuning rationale
│       └── infra.toml
├── config.env -> hardware/.../config.env  (symlink)
├── load-config.sh              # Config loader
└── *.sh                        # Setup scripts
```

### Generate New Hardware Context
```bash
cd scripts
./hardware/generate-config.sh <instance_type> <data_disks> <wal_disks> [raid_level]

# Example
./hardware/generate-config.sh r8g.4xlarge 16 8 raid10
```

### Use Specific Hardware Context
```bash
# Option 1: Environment variable
export HARDWARE_CONTEXT=c8gb.2xlarge.33.25.8disk.raid10
./05-db-install.sh

# Option 2: Symlink (default context)
ln -sf hardware/c8gb.2xlarge.33.25.8disk.raid10/config.env config.env
./05-db-install.sh
```

---

## Parameter Classification

| Parameter Type | Example | Derivable from Hardware? |
|---------------|---------|-------------------------|
| Memory-based | `shared_buffers = 25% RAM` | Yes - calculated |
| CPU-based | `max_parallel_workers = vCPU` | Yes - calculated |
| RAID-based | `effective_io_concurrency` | Yes - calculated |
| **Experience-tuned** | `bgwriter_delay = 10ms` | No - from benchmark |
| **Experience-tuned** | `commit_delay = 50` | No - from benchmark |
| **Experience-tuned** | `vm.dirty_background_ratio = 1` | No - from I/O cliff analysis |

### Calculated Parameters (from hardware specs)
```bash
shared_buffers = RAM_GB * 0.25
effective_cache_size = RAM_GB * 0.70
max_parallel_workers = vCPU
effective_io_concurrency = disk_count * 25
maintenance_work_mem = RAM_GB / 16 (min 1GB)
autovacuum_max_workers = vCPU / 4 (min 2, max 8)
```

### Experience-Tuned Parameters (from benchmarking)
These values were discovered through iterative benchmarking on EBS gp3:
```bash
# OS - Prevent I/O cliff
vm.dirty_background_ratio = 1    # Flush at 1% RAM dirty
vm.dirty_ratio = 4               # Block at 4%
vm.dirty_expire_centisecs = 200  # Data max 2s in RAM

# PostgreSQL - Background Writer
bgwriter_delay = 10ms            # 100x/sec instead of 5x/sec
bgwriter_lru_maxpages = 1000     # 8MB/round
bgwriter_lru_multiplier = 10.0   # Proactive cleanup

# PostgreSQL - Group Commit (for EBS ~1.8ms latency)
commit_delay = 50                # Wait 50µs to batch commits
commit_siblings = 10             # Only when ≥10 concurrent commits
```

---

## Graviton4 Instance Types

### Standard vs Block Optimized
| Suffix | Meaning | EBS Bandwidth |
|--------|---------|---------------|
| `g` | Standard | Up to 40 Gbps |
| `gd` | Local NVMe | Up to 40 Gbps |
| `gb` | Block optimized | Up to 150 Gbps |

### Supported Instance Families
```
c8g/c8gd/c8gb   - Compute optimized
r8g/r8gd/r8gb   - Memory optimized
m8g/m8gd        - General purpose
```

### Example Specs (from AWS docs)
| Instance | vCPU | RAM | Network | EBS |
|----------|------|-----|---------|-----|
| c8gb.2xlarge | 8 | 16 GB | 33 Gbps | 25 Gbps |
| c8gb.8xlarge | 32 | 64 GB | 66 Gbps | 50 Gbps |
| r8g.2xlarge | 8 | 64 GB | 15 Gbps | 10 Gbps |
| r8gb.4xlarge | 16 | 128 GB | 33 Gbps | 25 Gbps |

---

## PostgreSQL Configuration
- **Data Directory**: `/data/postgresql` (NOT /data/postgres)
- **Config Files**: `/data/postgresql/pg_hba.conf`
- **Logs**: `/data/postgresql/log/`
- **Port**: 5432

### pg_hba.conf (SECURE - NO TRUST)
```
local   all             postgres                                peer
local   all             all                                     peer
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256
host    all             all             10.0.0.0/16             scram-sha-256
```

**WARNING**: Never use `trust` for VPC/network access.

## PgCat Proxy Configuration
- **Binary**: `/usr/local/bin/pgcat`
- **Config**: `/etc/pgcat/pgcat.toml`
- **Service**: `systemctl status pgcat`
- **Port**: 5432
- **Password**: `postgres`

---

## Provisioning Steps

### Step 1: Terraform Apply
```bash
cd terraform
terraform init
terraform apply
```

Required variables in `terraform.tfvars`:
```hcl
key_name  = "dbdeepdive-key"
db_ami    = "ami-0266f4b9e2c1841fb"
proxy_ami = "ami-01efdecff661a215d"
```

### Step 2: Wait for DB Recovery
```bash
ssh -i ~/.ssh/id_rsa ubuntu@<DB_PUBLIC_IP>
sudo tail -f /data/postgresql/log/postgresql-$(date +%Y-%m-%d).log
```
Wait for: `database system is ready to accept connections`

### Step 3: Configure DB Authentication
```bash
ssh -i ~/.ssh/id_rsa ubuntu@<DB_PUBLIC_IP>
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"
```

### Step 4: Configure PgCat on Proxy
```bash
ssh -i ~/.ssh/id_rsa ubuntu@<PROXY_PUBLIC_IP>
sudo sed -i 's/\["10\.0\.[0-9]*\.[0-9]*"/["<DB_PRIVATE_IP>"/' /etc/pgcat/pgcat.toml
sudo systemctl restart pgcat
```

### Step 5: Verify Connectivity
```bash
PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres -d pgbench -c 'SELECT count(*) FROM pgbench_accounts;'
```

---

## Connection Strings
```bash
# Through PgCat proxy
PGPASSWORD=postgres psql -h <PROXY_IP> -U postgres -d pgbench

# Direct to DB (VPC only)
PGPASSWORD=postgres psql -h <DB_PRIVATE_IP> -U postgres -d pgbench

# SSH
ssh -i ~/.ssh/id_rsa ubuntu@<PUBLIC_IP>
```

---

## Troubleshooting

### DB Not Accepting Connections
AMI requires WAL recovery. Check logs:
```bash
sudo tail -f /data/postgresql/log/postgresql-$(date +%Y-%m-%d).log
```

### PgCat "Pool Down" or "TimedOut"
Test direct connection from proxy:
```bash
PGPASSWORD=postgres psql -h <DB_PRIVATE_IP> -U postgres -d pgbench -c 'SELECT 1;'
```

### vCPU Limit Exceeded
Use spot instances (already configured in terraform).

### Permission Denied (SSH)
Use `~/.ssh/id_rsa`, not the terraform key_name .pem file.
