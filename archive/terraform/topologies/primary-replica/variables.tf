# =============================================================================
# Primary + Replica Topology Variables
# =============================================================================

# AWS
variable "region" {
  type    = string
  default = "us-west-2"
}

variable "availability_zone" {
  type    = string
  default = "us-west-2a"
}

variable "aws_profile" {
  type    = string
  default = "default"
}

variable "project" {
  type    = string
  default = "dbdeepdive"
}

# Network
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

# Security
variable "ssh_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "postgres_access_enabled" {
  type    = bool
  default = false
}

variable "postgres_cidr_blocks" {
  type    = list(string)
  default = []
}

# SSH
variable "key_name" {
  type = string
}

variable "ssh_private_key" {
  type    = string
  default = "~/.ssh/id_rsa"
}

# PostgreSQL AMI
variable "postgres_ami" {
  type = string
}

# Primary Instance
variable "primary_instance_type" {
  type    = string
  default = "r8g.2xlarge"
}

variable "primary_spot_price" {
  type    = string
  default = "1.50"
}

# Replica Instance (can be smaller)
variable "replica_instance_type" {
  type    = string
  default = "r8g.xlarge"
}

variable "replica_spot_price" {
  type    = string
  default = "0.50"
}

# EBS Volumes
variable "create_ebs_volumes" {
  type    = bool
  default = false
}

variable "data_disk_count" {
  type    = number
  default = 8
}

variable "data_disk_size" {
  type    = number
  default = 50
}

variable "wal_disk_count" {
  type    = number
  default = 8
}

variable "wal_disk_size" {
  type    = number
  default = 30
}

variable "delete_volumes_on_termination" {
  type    = bool
  default = true
}

variable "set_delete_on_termination" {
  type    = bool
  default = true
}
