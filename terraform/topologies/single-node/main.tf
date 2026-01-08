# Single Node Topology - Disk Benchmark
# Uses r8g.xlarge (prod) with spot instance
# Static IP: 10.0.1.10

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
}

variable "aws_region" {
  default = "ap-southeast-1"
}

# Removed profile variable to use default environment credentials

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "dev-new"
}

variable "instance_type" {
  description = "Instance type (r8g.xlarge for prod)"
  default     = "r8g.xlarge"
}


# Ubuntu 24.04 ARM64 AMI (ap-southeast-1)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

# Network
module "network" {
  source            = "../../modules/network"
  availability_zone = "${var.aws_region}a"
}

# Security
module "security" {
  source   = "../../modules/security"
  vpc_id   = module.network.vpc_id
  vpc_cidr = module.network.vpc_cidr
}

# DB Node (Spot Instance)
module "db" {
  source = "../../modules/db-node"

  node_name         = "db"
  private_ip        = "10.0.1.10"
  instance_type     = var.instance_type
  ami_id            = data.aws_ami.ubuntu.id
  subnet_id         = module.network.subnet_id
  security_group_id = module.security.db_security_group_id
  key_name          = var.key_name
  availability_zone = "${var.aws_region}a"

  # RAID0: 4x DATA + 4x WAL
  data_volume_count = 4
  data_volume_size  = 50
  wal_volume_count  = 4
  wal_volume_size   = 30
}


# Instance type to hardware mapping
locals {
  instance_specs = {
    "c8g.4xlarge" = { vcpu = 16, ram_gb = 32 }
    "c8g.xlarge"  = { vcpu = 4, ram_gb = 8 }
    "r8g.xlarge"  = { vcpu = 4, ram_gb = 32 }
    "r8g.2xlarge" = { vcpu = 8, ram_gb = 64 }
  }
  
  current_specs = local.instance_specs[var.instance_type]
}

# Snapshot variables (optional, for Phase 2+)
variable "data_snapshot_id" {
  description = "EBS snapshot ID for DATA volume (optional)"
  default     = ""
}

variable "wal_snapshot_id" {
  description = "EBS snapshot ID for WAL volume (optional)"
  default     = ""
}

# ============================================================================
# OUTPUTS - Required for bootstrap.sh integration
# ============================================================================

output "topology" {
  value = "single-node"
}

output "aws_region" {
  value = var.aws_region
}

output "ssh_key_path" {
  value = "~/.ssh/id_rsa"
}

output "db_node" {
  value = {
    instance_id   = module.db.instance_id
    public_ip     = module.db.public_ip
    private_ip    = module.db.private_ip
    instance_type = var.instance_type
    vcpu          = local.current_specs.vcpu
    ram_gb        = local.current_specs.ram_gb
  }
}

output "storage" {
  value = {
    data_volumes  = module.db.data_volume_ids
    wal_volumes   = module.db.wal_volume_ids
    from_snapshot = var.data_snapshot_id != ""
    data_snapshot = var.data_snapshot_id
    wal_snapshot  = var.wal_snapshot_id
  }
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/id_rsa ubuntu@${module.db.public_ip}"
}
