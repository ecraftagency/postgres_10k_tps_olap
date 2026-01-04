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

## Current Deployment (2026-01-04)
| Component | Public IP | Private IP | Instance Type |
|-----------|-----------|------------|---------------|
| DB (postgres-master) | 44.243.33.82 | 10.0.1.207 | c8gb.8xlarge |
| Proxy (pgcat-proxy) | 44.243.31.234 | 10.0.1.138 | c8g.2xlarge |

## AMI Configuration
| Component | AMI ID | Description |
|-----------|--------|-------------|
| DB | `ami-0c84db895917f789c` | PostgreSQL 16 + 16 EBS volumes (RAID10) |
| Proxy | `ami-012798e88aebdba5c` | Ubuntu 24.04 ARM64 |

**IMPORTANT**: DB AMI includes all EBS volumes from snapshots. Do NOT create separate EBS volumes in terraform.

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
# VPC Access - REQUIRE PASSWORD (NEVER use trust in production!)
host    all             all             10.0.0.0/16             scram-sha-256
```

**WARNING**: Never use `trust` for VPC/network access. If any machine in VPC is compromised, attacker gets full DB access without password.

## PgCat Proxy Configuration
- **Binary**: `/usr/local/bin/pgcat`
- **Config**: `/etc/pgcat/pgcat.toml`
- **Service**: `systemctl status pgcat`
- **Port**: 5432 (default PostgreSQL port)
- **Pool**: `pgbench`
- **Client Password**: `postgres`
- **DB User Password**: `postgres` (set via `ALTER USER postgres PASSWORD 'postgres';`)

## Connection Strings
```bash
# Through PgCat proxy (password required) - default port 5432
PGPASSWORD=postgres psql -h <PROXY_IP> -U postgres -d pgbench

# Direct to DB from within VPC (trust auth)
psql -h <DB_PRIVATE_IP> -U postgres -d pgbench

# SSH
ssh -i ~/.ssh/id_rsa ubuntu@<PUBLIC_IP>
```

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
key_name = "dbdeepdive-key"
db_ami   = "ami-0c84db895917f789c"
```

### Step 2: Wait for DB Recovery
After launch, DB needs WAL recovery (2-5 minutes). Monitor:
```bash
ssh -i ~/.ssh/id_rsa ubuntu@<DB_PUBLIC_IP>
sudo tail -f /data/postgresql/log/postgresql-$(date +%Y-%m-%d).log
```
Wait for: `database system is ready to accept connections`

### Step 3: Configure DB Authentication
SSH to DB, set password, and configure secure pg_hba.conf:
```bash
ssh -i ~/.ssh/id_rsa ubuntu@<DB_PUBLIC_IP>

# Set postgres password
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"

# Configure pg_hba.conf (NEVER use trust for VPC!)
sudo tee /data/postgresql/pg_hba.conf > /dev/null << 'EOF'
local   all             postgres                                peer
local   all             all                                     peer
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256
host    all             all             10.0.0.0/16             scram-sha-256
EOF
sudo -u postgres psql -c 'SELECT pg_reload_conf();'
```

### Step 4: Install PgCat on Proxy
```bash
# Copy scripts to proxy
scp -i ~/.ssh/id_rsa -r scripts/pgcat ubuntu@<PROXY_PUBLIC_IP>:/tmp/

# SSH to proxy and install
ssh -i ~/.ssh/id_rsa ubuntu@<PROXY_PUBLIC_IP>

# Write config directly (install.sh copies wrong default config)
sudo mkdir -p /etc/pgcat
sudo tee /etc/pgcat/pgcat.toml > /dev/null << 'EOF'
[general]
host = "0.0.0.0"
port = 5432
admin_username = "admin"
admin_password = "admin_secure"
worker_threads = 8
connect_timeout = 5000
idle_timeout = 60000
prometheus_exporter_port = 9090
log_client_connections = false
log_client_disconnections = false
auth_type = "trust"

[pools.pgbench]
pool_mode = "transaction"
default_role = "primary"
query_parser_enabled = true
primary_reads_enabled = true
pool_size = 250
min_pool_size = 10
load_balancing_mode = "random"

[pools.pgbench.users.0]
username = "postgres"
password = "postgres"
pool_size = 250

[pools.pgbench.shards.0]
database = "pgbench"
servers = [
    ["<DB_PRIVATE_IP>", 5432, "primary"]
]
EOF

# Run install script (builds pgcat binary)
chmod +x /tmp/pgcat/install.sh
/tmp/pgcat/install.sh <DB_PRIVATE_IP>

# Start service
sudo systemctl enable --now pgcat
sudo systemctl status pgcat
```

### Step 5: Verify Connectivity
```bash
# From proxy, test through pgcat (default port 5432)
PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres -d pgbench -c 'SELECT count(*) FROM pgbench_accounts;'
```

---

## Troubleshooting

### DB Not Accepting Connections After Launch
AMI requires WAL recovery. Check logs:
```bash
sudo tail -f /data/postgresql/log/postgresql-$(date +%Y-%m-%d).log
```

### PgCat "Pool Down" or "TimedOut"
1. Test direct connection from proxy to DB:
   ```bash
   psql -h <DB_PRIVATE_IP> -U postgres -d pgbench -c 'SELECT 1;'
   ```
2. If asks for password: pg_hba.conf order is wrong (VPC trust must come before 0.0.0.0/0)
3. Fix and reload: `sudo -u postgres psql -c 'SELECT pg_reload_conf();'`

### PgCat Wrong Config
The install script may copy default example config. Always write config directly as shown in Step 4.

### vCPU Limit Exceeded
Use spot instances (already configured in terraform).

### Key Pair Not Found
Ensure key exists in boxloop-admin account:
```bash
aws ec2 describe-key-pairs --key-names dbdeepdive-key --profile boxloop-admin
```

### Permission Denied (SSH)
Use `~/.ssh/id_rsa`, not the terraform key_name .pem file.
