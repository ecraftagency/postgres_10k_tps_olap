# Proxy-Primary Topology
# Primary DB: r8g.xlarge (10.0.1.10)
# Proxy/Benchmark: r8g.large (10.0.1.20)

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
  default = "r8g.xlarge"
}

variable "proxy_instance_type" {
  default = "c8g.xlarge"
}

# Ubuntu 24.04 ARM64 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

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

# Primary DB Node (Spot)
module "db" {
  source = "../../modules/db-node"

  node_name         = "primary"
  private_ip        = "10.0.1.10"
  instance_type     = var.db_instance_type
  ami_id            = data.aws_ami.ubuntu.id
  subnet_id         = module.network.subnet_id
  security_group_id = module.security.db_security_group_id
  key_name          = aws_key_pair.main.key_name
  availability_zone = "${var.aws_region}a"

  # RAID0: 4x DATA + 4x WAL
  data_volume_count = 4
  wal_volume_count  = 4
}

# Proxy/Benchmark Node (Spot)
# Using a simpler instance without extra EBS volumes for now
resource "aws_spot_instance_request" "proxy" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.proxy_instance_type
  subnet_id              = module.network.subnet_id
  private_ip             = "10.0.1.20"
  vpc_security_group_ids = [module.security.db_security_group_id]
  key_name               = aws_key_pair.main.key_name

  spot_type            = "one-time"
  wait_for_fulfillment = true

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
    "r8g.large"  = { vcpu = 2, ram_gb = 16 }
    "r8g.xlarge" = { vcpu = 4, ram_gb = 32 }
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "topology" {
  value = "proxy-primary"
}

output "db_node" {
  value = {
    instance_id   = module.db.instance_id
    public_ip     = module.db.public_ip
    private_ip    = module.db.private_ip
    instance_type = var.db_instance_type
    vcpu          = local.specs[var.db_instance_type].vcpu
    ram_gb        = local.specs[var.db_instance_type].ram_gb
  }
}

output "proxy_node" {
  value = {
    instance_id   = aws_spot_instance_request.proxy.spot_instance_id
    public_ip     = aws_spot_instance_request.proxy.public_ip
    private_ip    = aws_spot_instance_request.proxy.private_ip
    instance_type = var.proxy_instance_type
    vcpu          = local.specs[var.proxy_instance_type].vcpu
    ram_gb        = local.specs[var.proxy_instance_type].ram_gb
  }
}

output "storage" {
  value = {
    data_volumes = module.db.data_volume_ids
    wal_volumes  = module.db.wal_volume_ids
  }
}
