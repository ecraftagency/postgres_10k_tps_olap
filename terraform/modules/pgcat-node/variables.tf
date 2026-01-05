# =============================================================================
# PgCat Node Module Variables
# =============================================================================

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

variable "instance_type" {
  description = "EC2 instance type (compute optimized recommended)"
  type        = string
  default     = "c8g.xlarge"
}

variable "spot_price" {
  description = "Maximum spot price"
  type        = string
  default     = "0.20"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "node_name" {
  description = "Name tag for the instance"
  type        = string
  default     = "pgcat-proxy"
}
