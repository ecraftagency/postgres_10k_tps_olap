# =============================================================================
# Single Node Topology Variables
# =============================================================================

# -----------------------------------------------------------------------------
# AWS Configuration
# -----------------------------------------------------------------------------

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "availability_zone" {
  description = "AWS availability zone"
  type        = string
  default     = "us-west-2a"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------

variable "project" {
  description = "Project name for resource tagging"
  type        = string
  default     = "dbdeepdive"
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR block"
  type        = string
  default     = "10.0.1.0/24"
}

# -----------------------------------------------------------------------------
# Security Configuration
# -----------------------------------------------------------------------------

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "postgres_access_enabled" {
  description = "Enable external PostgreSQL access"
  type        = bool
  default     = false
}

variable "postgres_cidr_blocks" {
  description = "CIDR blocks for PostgreSQL access"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# SSH Configuration
# -----------------------------------------------------------------------------

variable "key_name" {
  description = "SSH key pair name in AWS"
  type        = string
}

variable "ssh_private_key" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/id_rsa"
}

# -----------------------------------------------------------------------------
# PostgreSQL Instance Configuration
# -----------------------------------------------------------------------------

variable "postgres_ami" {
  description = "AMI ID for PostgreSQL instance"
  type        = string
}

variable "postgres_instance_type" {
  description = "Instance type for PostgreSQL"
  type        = string
  default     = "r8g.2xlarge"
}

variable "postgres_spot_price" {
  description = "Maximum spot price for PostgreSQL instance"
  type        = string
  default     = "1.50"
}

# -----------------------------------------------------------------------------
# EBS Volume Configuration
# -----------------------------------------------------------------------------

variable "create_ebs_volumes" {
  description = "Create new EBS volumes (false if AMI has volumes)"
  type        = bool
  default     = false
}

variable "data_disk_count" {
  description = "Number of data disks"
  type        = number
  default     = 8
}

variable "data_disk_size" {
  description = "Size of each data disk in GB"
  type        = number
  default     = 50
}

variable "data_disk_iops" {
  description = "IOPS for data disks"
  type        = number
  default     = 3000
}

variable "data_disk_throughput" {
  description = "Throughput for data disks (MB/s)"
  type        = number
  default     = 125
}

variable "wal_disk_count" {
  description = "Number of WAL disks"
  type        = number
  default     = 8
}

variable "wal_disk_size" {
  description = "Size of each WAL disk in GB"
  type        = number
  default     = 30
}

variable "wal_disk_iops" {
  description = "IOPS for WAL disks"
  type        = number
  default     = 3000
}

variable "wal_disk_throughput" {
  description = "Throughput for WAL disks (MB/s)"
  type        = number
  default     = 125
}

variable "delete_volumes_on_termination" {
  description = "Delete EBS volumes on instance termination"
  type        = bool
  default     = true
}

variable "set_delete_on_termination" {
  description = "Run script to set DeleteOnTermination for AMI volumes"
  type        = bool
  default     = true
}
