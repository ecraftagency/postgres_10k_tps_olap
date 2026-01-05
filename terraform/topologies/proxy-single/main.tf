# =============================================================================
# Topology: Proxy + Single Node PostgreSQL
# =============================================================================
# PgCat connection pooler in front of single PostgreSQL
# Use case: Connection pooling, read scaling preparation
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

# =============================================================================
# Network
# =============================================================================

module "network" {
  source = "../../modules/network"

  project           = var.project
  vpc_cidr          = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone = var.availability_zone
}

# =============================================================================
# Security
# =============================================================================

module "security" {
  source = "../../modules/security"

  project = var.project
  vpc_id  = module.network.vpc_id

  ssh_cidr_blocks      = var.ssh_cidr_blocks
  pgcat_access_enabled = var.pgcat_access_enabled
  pgcat_cidr_blocks    = var.pgcat_cidr_blocks
}

# =============================================================================
# PostgreSQL Node
# =============================================================================

module "postgres" {
  source = "../../modules/postgres-node"

  region            = var.region
  ami_id            = var.postgres_ami
  instance_type     = var.postgres_instance_type
  spot_price        = var.postgres_spot_price
  key_name          = var.key_name
  subnet_id         = module.network.public_subnet_id
  security_group_id = module.security.shared_security_group_id

  node_name = "postgres-master"
  node_role = "standalone"

  create_ebs_volumes            = var.create_ebs_volumes
  data_disk_count               = var.data_disk_count
  data_disk_size                = var.data_disk_size
  wal_disk_count                = var.wal_disk_count
  wal_disk_size                 = var.wal_disk_size
  delete_volumes_on_termination = var.delete_volumes_on_termination
  set_delete_on_termination     = var.set_delete_on_termination
}

# =============================================================================
# PgCat Proxy Node
# =============================================================================

module "pgcat" {
  source = "../../modules/pgcat-node"

  ami_id            = var.pgcat_ami
  instance_type     = var.pgcat_instance_type
  spot_price        = var.pgcat_spot_price
  key_name          = var.key_name
  subnet_id         = module.network.public_subnet_id
  security_group_id = module.security.shared_security_group_id

  node_name = "pgcat-proxy"
}

# =============================================================================
# Connection Info
# =============================================================================

resource "local_file" "connection_info" {
  content = jsonencode({
    topology             = "proxy-single"
    postgres_public_ip   = module.postgres.public_ip
    postgres_private_ip  = module.postgres.private_ip
    postgres_instance_id = module.postgres.instance_id
    pgcat_public_ip      = module.pgcat.public_ip
    pgcat_private_ip     = module.pgcat.private_ip
    pgcat_instance_id    = module.pgcat.instance_id
    ssh_postgres         = "ssh -i ${var.ssh_private_key} ubuntu@${module.postgres.public_ip}"
    ssh_pgcat            = "ssh -i ${var.ssh_private_key} ubuntu@${module.pgcat.public_ip}"
    postgres_instance_type = var.postgres_instance_type
    pgcat_instance_type    = var.pgcat_instance_type
    created_at           = timestamp()
  })
  filename = "${path.module}/connection.json"
}
