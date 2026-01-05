# =============================================================================
# Topology: Primary + Replica PostgreSQL
# =============================================================================
# PostgreSQL streaming replication setup
# Use case: High availability, read scaling
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

  ssh_cidr_blocks         = var.ssh_cidr_blocks
  postgres_access_enabled = var.postgres_access_enabled
  postgres_cidr_blocks    = var.postgres_cidr_blocks
}

# =============================================================================
# Primary PostgreSQL Node
# =============================================================================

module "primary" {
  source = "../../modules/postgres-node"

  region            = var.region
  ami_id            = var.postgres_ami
  instance_type     = var.primary_instance_type
  spot_price        = var.primary_spot_price
  key_name          = var.key_name
  subnet_id         = module.network.public_subnet_id
  security_group_id = module.security.shared_security_group_id

  node_name = "postgres-primary"
  node_role = "primary"

  create_ebs_volumes            = var.create_ebs_volumes
  data_disk_count               = var.data_disk_count
  data_disk_size                = var.data_disk_size
  wal_disk_count                = var.wal_disk_count
  wal_disk_size                 = var.wal_disk_size
  delete_volumes_on_termination = var.delete_volumes_on_termination
  set_delete_on_termination     = var.set_delete_on_termination
}

# =============================================================================
# Replica PostgreSQL Node
# =============================================================================

module "replica" {
  source = "../../modules/postgres-node"

  region            = var.region
  ami_id            = var.postgres_ami
  instance_type     = var.replica_instance_type
  spot_price        = var.replica_spot_price
  key_name          = var.key_name
  subnet_id         = module.network.public_subnet_id
  security_group_id = module.security.shared_security_group_id

  node_name = "postgres-replica"
  node_role = "replica"

  create_ebs_volumes            = var.create_ebs_volumes
  data_disk_count               = var.data_disk_count
  data_disk_size                = var.data_disk_size
  wal_disk_count                = var.wal_disk_count
  wal_disk_size                 = var.wal_disk_size
  delete_volumes_on_termination = var.delete_volumes_on_termination
  set_delete_on_termination     = var.set_delete_on_termination
}

# =============================================================================
# Connection Info
# =============================================================================

resource "local_file" "connection_info" {
  content = jsonencode({
    topology            = "primary-replica"
    primary_public_ip   = module.primary.public_ip
    primary_private_ip  = module.primary.private_ip
    primary_instance_id = module.primary.instance_id
    replica_public_ip   = module.replica.public_ip
    replica_private_ip  = module.replica.private_ip
    replica_instance_id = module.replica.instance_id
    ssh_primary         = "ssh -i ${var.ssh_private_key} ubuntu@${module.primary.public_ip}"
    ssh_replica         = "ssh -i ${var.ssh_private_key} ubuntu@${module.replica.public_ip}"
    primary_instance_type = var.primary_instance_type
    replica_instance_type = var.replica_instance_type
    created_at          = timestamp()
  })
  filename = "${path.module}/connection.json"
}
