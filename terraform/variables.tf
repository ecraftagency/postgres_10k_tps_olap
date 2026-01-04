variable "region" {
  default = "us-west-2"
}

variable "az" {
  default = "us-west-2a"
}

variable "instance_type" {
  # r8g.xlarge: Memory optimized, Graviton4
  # 4 vCPU, 32 GB RAM, 12.5 Gbps network, 10 Gbps EBS
  # Target: 10K TPS @ $145/month (50% cost reduction)
  default = "r8g.xlarge"
}

variable "ami" {
  description = "Ubuntu 24.04 LTS ARM64 (us-west-2)"
  default     = "ami-012798e88aebdba5c"
}

variable "db_ami" {
  description = "Pre-configured PostgreSQL AMI with data at /data/postgresql (restore from snapshot)"
  type        = string
}

variable "proxy_ami" {
  description = "Pre-configured PgCat proxy AMI"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name in AWS"
  type        = string
}

variable "ssh_private_key" {
  description = "Path to SSH private key for connections"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  default = "10.0.1.0/24"
}
