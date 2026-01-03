variable "region" {
  default = "us-west-2"
}

variable "az" {
  default = "us-west-2a"
}

variable "instance_type" {
  default = "c7g.2xlarge"
}

variable "ami" {
  description = "Ubuntu 24.04 LTS ARM64 (us-west-2)"
  default     = "ami-012798e88aebdba5c"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "spot_price" {
  default = "0.60"
}

variable "pg_data_volume_count" {
  default = 8
}

variable "pg_data_volume_size" {
  default = 50
}

variable "pg_wal_volume_count" {
  default = 8
}

variable "pg_wal_volume_size" {
  default = 30
}
