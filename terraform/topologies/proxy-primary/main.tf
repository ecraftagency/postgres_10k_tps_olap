# =============================================================================
# Proxy-Primary-Replicas Topology
# =============================================================================
# Primary DB:     r7g.xlarge (10.0.1.10)
# Sync Replica:   r7g.xlarge (10.0.1.11)
# Async Replica:  r7g.xlarge (10.0.1.12)
# Proxy/Bench:    c8g.xlarge (10.0.1.20)
# =============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-southeast-1"
  profile = "boxloop-admin"
}

variable "aws_region" {
  default = "ap-southeast-1"
}

variable "aws_profile" {
  default = "boxloop-admin"
}

variable "ssh_public_key_path" {
  default = "/Users/vunguyen/.ssh/id_rsa.pub"
}

# Explicitly manage the key pair to ensure matches with local ~/.ssh/id_rsa
resource "aws_key_pair" "main" {
  key_name   = "dbdeepdive-key"
  public_key = file(var.ssh_public_key_path)
}

variable "db_instance_type" {
  default = "r7g.xlarge"  # r8g.xlarge spot unavailable in ap-southeast-1
}

variable "proxy_instance_type" {
  default = "c8g.xlarge"
}

# Base Ubuntu 24.04 ARM64 AMI (golden AMIs unavailable)
variable "db_ami_id" {
  default = "ami-054240677cb44ffac"  # ubuntu-noble-24.04-arm64-server-20251212
}

variable "proxy_ami_id" {
  default = "ami-054240677cb44ffac"  # ubuntu-noble-24.04-arm64-server-20251212
}

# Network
module "network" {
  source            = "../../modules/network"
  availability_zone = "${var.aws_region}b"
}

# Security
module "security" {
  source   = "../../modules/security"
  vpc_id   = module.network.vpc_id
  vpc_cidr = module.network.vpc_cidr
}

# =============================================================================
# DB NODES
# =============================================================================

# Primary DB Node (Spot)
module "primary" {
  source = "../../modules/db-node"

  node_name         = "primary"
  private_ip        = "10.0.1.10"
  instance_type     = var.db_instance_type
  ami_id            = var.db_ami_id
  subnet_id         = module.network.subnet_id
  security_group_id = module.security.db_security_group_id
  key_name          = aws_key_pair.main.key_name
  availability_zone = "${var.aws_region}b"

  # Fresh EBS volumes for RAID setup
  data_volume_count = 4
  wal_volume_count  = 4
  data_volume_size  = 50  # GB per volume
  wal_volume_size   = 30  # GB per volume
}

# Sync Replica DB Node (Spot)
module "sync_replica" {
  source = "../../modules/db-node"

  node_name         = "sync-replica"
  private_ip        = "10.0.1.11"
  instance_type     = var.db_instance_type
  ami_id            = var.db_ami_id
  subnet_id         = module.network.subnet_id
  security_group_id = module.security.db_security_group_id
  key_name          = aws_key_pair.main.key_name
  availability_zone = "${var.aws_region}b"

  # Same storage config as primary
  data_volume_count = 4
  wal_volume_count  = 4
  data_volume_size  = 50
  wal_volume_size   = 30
}

# Async Replica DB Node (Spot)
module "async_replica" {
  source = "../../modules/db-node"

  node_name         = "async-replica"
  private_ip        = "10.0.1.12"
  instance_type     = var.db_instance_type
  ami_id            = var.db_ami_id
  subnet_id         = module.network.subnet_id
  security_group_id = module.security.db_security_group_id
  key_name          = aws_key_pair.main.key_name
  availability_zone = "${var.aws_region}b"

  # Same storage config as primary
  data_volume_count = 4
  wal_volume_count  = 4
  data_volume_size  = 50
  wal_volume_size   = 30
}

# =============================================================================
# PROXY NODE
# =============================================================================

# Proxy/Benchmark Node (on-demand for reliability)
resource "aws_instance" "proxy" {
  ami                    = var.proxy_ami_id
  instance_type          = var.proxy_instance_type
  subnet_id              = module.network.subnet_id
  private_ip             = "10.0.1.20"
  vpc_security_group_ids = [module.security.db_security_group_id]
  key_name               = aws_key_pair.main.key_name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "dbdeepdive-proxy"
  }
}

# Instance specs for output
locals {
  specs = {
    "c8g.xlarge" = { vcpu = 4, ram_gb = 8 }
    "r7g.xlarge" = { vcpu = 4, ram_gb = 32 }
    "r8g.large"  = { vcpu = 2, ram_gb = 16 }
    "r8g.xlarge" = { vcpu = 4, ram_gb = 32 }
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "topology" {
  value = "proxy-primary-replicas"
}

output "db_nodes" {
  value = {
    primary = {
      instance_id   = module.primary.instance_id
      public_ip     = module.primary.public_ip
      private_ip    = module.primary.private_ip
      instance_type = var.db_instance_type
      vcpu          = local.specs[var.db_instance_type].vcpu
      ram_gb        = local.specs[var.db_instance_type].ram_gb
      role          = "primary"
    }
    sync_replica = {
      instance_id   = module.sync_replica.instance_id
      public_ip     = module.sync_replica.public_ip
      private_ip    = module.sync_replica.private_ip
      instance_type = var.db_instance_type
      vcpu          = local.specs[var.db_instance_type].vcpu
      ram_gb        = local.specs[var.db_instance_type].ram_gb
      role          = "sync-replica"
    }
    async_replica = {
      instance_id   = module.async_replica.instance_id
      public_ip     = module.async_replica.public_ip
      private_ip    = module.async_replica.private_ip
      instance_type = var.db_instance_type
      vcpu          = local.specs[var.db_instance_type].vcpu
      ram_gb        = local.specs[var.db_instance_type].ram_gb
      role          = "async-replica"
    }
  }
}

output "proxy_node" {
  value = {
    instance_id   = aws_instance.proxy.id
    public_ip     = aws_instance.proxy.public_ip
    private_ip    = aws_instance.proxy.private_ip
    instance_type = var.proxy_instance_type
    vcpu          = local.specs[var.proxy_instance_type].vcpu
    ram_gb        = local.specs[var.proxy_instance_type].ram_gb
  }
}

output "storage" {
  value = {
    primary_data_volumes       = module.primary.data_volume_ids
    primary_wal_volumes        = module.primary.wal_volume_ids
    sync_replica_data_volumes  = module.sync_replica.data_volume_ids
    sync_replica_wal_volumes   = module.sync_replica.wal_volume_ids
    async_replica_data_volumes = module.async_replica.data_volume_ids
    async_replica_wal_volumes  = module.async_replica.wal_volume_ids
  }
}
