# Terraform Infrastructure

Modular Terraform configuration for PostgreSQL benchmarking infrastructure.

## Structure

```
terraform/
├── modules/                    # Reusable components
│   ├── network/               # VPC, subnets, IGW, routes
│   ├── security/              # Security groups
│   ├── postgres-node/         # PostgreSQL EC2 + RAID10
│   └── pgcat-node/            # Connection pooler
│
├── topologies/                # Hardware layouts
│   ├── single-node/          # Just PostgreSQL
│   ├── proxy-single/         # PgCat + PostgreSQL
│   └── primary-replica/      # PostgreSQL HA
│
└── hardware/                  # Instance configurations
    ├── r8g.xlarge.tfvars     # 4 vCPU, 32GB
    ├── r8g.2xlarge.tfvars    # 8 vCPU, 64GB
    ├── r8g.4xlarge.tfvars    # 16 vCPU, 128GB
    └── c8g.2xlarge.tfvars    # 8 vCPU, 16GB (compute)
```

## Quick Start

### 1. Single Node (Most Common)

```bash
cd terraform/topologies/single-node

# Initialize
terraform init

# Deploy with r8g.2xlarge
terraform apply \
  -var="aws_profile=boxloop-admin" \
  -var="key_name=dbdeepdive-key" \
  -var="postgres_ami=ami-0266f4b9e2c1841fb" \
  -var-file=../../hardware/r8g.2xlarge.tfvars

# Or with r8g.xlarge (smaller, cheaper)
terraform apply \
  -var="aws_profile=boxloop-admin" \
  -var="key_name=dbdeepdive-key" \
  -var="postgres_ami=ami-0266f4b9e2c1841fb" \
  -var-file=../../hardware/r8g.xlarge.tfvars
```

### 2. Proxy + Single Node

```bash
cd terraform/topologies/proxy-single

terraform apply \
  -var="aws_profile=boxloop-admin" \
  -var="key_name=dbdeepdive-key" \
  -var="postgres_ami=ami-xxx" \
  -var="pgcat_ami=ami-yyy" \
  -var-file=../../hardware/r8g.2xlarge.tfvars
```

### 3. Primary + Replica

```bash
cd terraform/topologies/primary-replica

terraform apply \
  -var="aws_profile=boxloop-admin" \
  -var="key_name=dbdeepdive-key" \
  -var="postgres_ami=ami-xxx" \
  -var="primary_instance_type=r8g.2xlarge" \
  -var="replica_instance_type=r8g.xlarge"
```

## Outputs

After deployment, connection info is saved to `connection.json`:

```json
{
  "topology": "single-node",
  "postgres_public_ip": "34.220.161.213",
  "postgres_private_ip": "10.0.1.248",
  "ssh_command": "ssh -i ~/.ssh/id_rsa ubuntu@34.220.161.213",
  "rsync_command": "rsync -avz ... scripts2/ ubuntu@...",
  "instance_type": "r8g.2xlarge"
}
```

## Hardware Configurations

| Config | Instance | vCPU | RAM | Target TPS | Cost/mo |
|--------|----------|------|-----|------------|---------|
| r8g.xlarge | Memory optimized | 4 | 32GB | 10K | $145 |
| r8g.2xlarge | Memory optimized | 8 | 64GB | 20K | $290 |
| r8g.4xlarge | Memory optimized | 16 | 128GB | 40K | $580 |
| c8g.2xlarge | Compute optimized | 8 | 16GB | CPU-bound | $200 |

## Destroy

```bash
cd terraform/topologies/single-node
terraform destroy
```

## Notes

- All instances use Spot pricing by default
- EBS volumes are deleted on termination
- Security groups allow SSH from anywhere (restrict in production)
- Each topology maintains separate Terraform state
