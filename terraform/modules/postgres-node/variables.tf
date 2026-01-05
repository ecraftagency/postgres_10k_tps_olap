# =============================================================================
# PostgreSQL Node Module Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "ami_id" {
  description = "AMI ID for the instance"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to launch instance in"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to attach"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

# -----------------------------------------------------------------------------
# Instance Configuration
# -----------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "r8g.2xlarge"
}

variable "spot_price" {
  description = "Maximum spot price (set high to avoid interruption)"
  type        = string
  default     = "1.50"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "node_name" {
  description = "Name tag for the instance"
  type        = string
  default     = "postgres"
}

variable "node_role" {
  description = "Role tag (primary, replica, standalone)"
  type        = string
  default     = "standalone"
}

# -----------------------------------------------------------------------------
# EBS Volume Configuration
# -----------------------------------------------------------------------------

variable "create_ebs_volumes" {
  description = "Whether to create new EBS volumes (false if using AMI with volumes)"
  type        = bool
  default     = true
}

variable "data_disk_count" {
  description = "Number of data disks for RAID"
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
  description = "Throughput for data disks in MB/s"
  type        = number
  default     = 125
}

variable "wal_disk_count" {
  description = "Number of WAL disks for RAID"
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
  description = "Throughput for WAL disks in MB/s"
  type        = number
  default     = 125
}

variable "delete_volumes_on_termination" {
  description = "Delete EBS volumes when instance terminates"
  type        = bool
  default     = true
}

variable "set_delete_on_termination" {
  description = "Run script to set DeleteOnTermination for AMI-attached volumes"
  type        = bool
  default     = false
}
