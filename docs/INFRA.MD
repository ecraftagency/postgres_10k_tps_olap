# INFRASTRUCTURE SPEC: PostgreSQL + PgCat + RisingWave

## Architecture Overview

```
                    ┌─────────────────┐
                    │     PgCat       │
                    │ (c8gb.2xlarge)  │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │  Postgres   │  │  Postgres   │  │  RisingWave │
    │   Master    │  │   Replica   │  │ (Standalone)│
    │(c8gb.2xlarge)│ │(c8gb.2xlarge)│ │(c8gb.2xlarge)│
    └─────────────┘  └─────────────┘  └─────────────┘
```

## Instance Specification

| Spec | Value | Source |
|------|-------|--------|
| Instance Type | **c8gb.2xlarge** | Block storage optimized |
| Family | c8gb | Graviton4, compute + block storage |
| Architecture | arm64 | AWS Graviton4 |
| vCPU | 8 | |
| Memory | 16 GB | |
| Network Bandwidth | **33.33 Gbps** | Enhanced networking |
| EBS Bandwidth | **25 Gbps** (3125 MB/s) | Instance limit |
| EBS IOPS | 40,000 | Instance limit |

**Reference:** https://instances.vantage.sh/aws/ec2/c8gb.2xlarge

## Common Specs
- Region: ap-southeast-7 (Bangkok)
- OS: Ubuntu 24.04 LTS ARM64
- Cost: AWS Spot Instances
- Network: Public subnet, shared Security Group (port 22 only)

## Node Types

### 1. PostgreSQL Nodes (Master + Replica)

| Component | Spec |
|-----------|------|
| Data RAID | RAID10, 8x50GB gp3 (3000 IOPS each), mount `/data` |
| WAL RAID | RAID10, 8x30GB gp3 (3000 IOPS each), mount `/wal` |
| Filesystem | XFS, noatime, nodiratime, aligned to RAID |

**Performance Ceilings (from infra.toml):**

| Metric | DATA Volume | WAL Volume |
|--------|-------------|------------|
| Read IOPS | 24,000 (8 disks × 3000) | 24,000 |
| Write IOPS | 12,000 (4 data disks × 3000) | 12,000 |
| Throughput | 500 MB/s (4 × 125) | 500 MB/s |
| QD1 IOPS | N/A | 2,000 (EBS latency-bound) |

### 2. PgCat Node
| Component | Spec |
|-----------|------|
| Storage | Root volume only |
| Role | Connection pooling, load balancing |

### 3. RisingWave Node
| Component | Spec |
|-----------|------|
| Data RAID | RAID0, 2x128GB gp3, 3000 IOPS |
| Mount | `/data` |
| Mode | Standalone |

## Configuration Files

| File | Purpose |
|------|---------|
| `scripts/config.env` | OS tuning, RAID, XFS, block device, thresholds |
| `scripts/infra.toml` | Instance specs, EBS specs, dynamic ceilings |

## Deployment Phases
1. **Phase 1**: Provision 1 PostgreSQL instance (hardware + storage)
2. **Phase 2**: OS tuning + RAID setup + PostgreSQL install
3. **Phase 3**: PgCat node
4. **Phase 4**: RisingWave node
5. **Phase 5**: Integration + benchmarking
