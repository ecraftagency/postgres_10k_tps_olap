# =============================================================================
# Security Module Variables
# =============================================================================

variable "project" {
  description = "Project name for resource tagging"
  type        = string
  default     = "dbdeepdive"
}

variable "vpc_id" {
  description = "VPC ID to create security group in"
  type        = string
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "postgres_access_enabled" {
  description = "Enable PostgreSQL port access from outside"
  type        = bool
  default     = false
}

variable "postgres_cidr_blocks" {
  description = "CIDR blocks allowed for PostgreSQL access"
  type        = list(string)
  default     = []
}

variable "pgcat_access_enabled" {
  description = "Enable PgCat port access from outside"
  type        = bool
  default     = false
}

variable "pgcat_cidr_blocks" {
  description = "CIDR blocks allowed for PgCat access"
  type        = list(string)
  default     = []
}
