# DB Node Module - EC2 Spot Instance + EBS
# Always uses spot instance (cheaper for benchmarking)
# Volumes terminate with instance

variable "project_name" {
  default = "dbdeepdive"
}

variable "node_name" {
  description = "Name for this node (primary, replica, etc.)"
  type        = string
}

variable "private_ip" {
  description = "Fixed private IP for this node"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "r8g.xlarge"
}

variable "ami_id" {
  description = "AMI ID (Ubuntu 24.04 ARM64)"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for volumes"
  type        = string
}

# EBS Volume Config
variable "data_volume_count" {
  default = 4
}

variable "data_volume_size" {
  default = 50
}

variable "wal_volume_count" {
  default = 4
}

variable "wal_volume_size" {
  default = 30
}

variable "ebs_iops" {
  default = 3000
}

variable "ebs_throughput" {
  default = 125
}

# EC2 Spot Instance
resource "aws_spot_instance_request" "db" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  private_ip           = var.private_ip
  vpc_security_group_ids = [var.security_group_id]
  key_name             = var.key_name

  spot_type            = "one-time"
  wait_for_fulfillment = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-${var.node_name}"
  }
}

# DATA Volumes (RAID0)
resource "aws_ebs_volume" "data" {
  count             = var.data_volume_count
  availability_zone = var.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  iops              = var.ebs_iops
  throughput        = var.ebs_throughput

  tags = {
    Name = "${var.project_name}-${var.node_name}-data-${count.index}"
  }
}

resource "aws_volume_attachment" "data" {
  count       = var.data_volume_count
  device_name = "/dev/sd${element(["f", "g", "h", "i"], count.index)}"
  volume_id   = aws_ebs_volume.data[count.index].id
  instance_id = aws_spot_instance_request.db.spot_instance_id
  force_detach = true
}

# WAL Volumes (RAID0)
resource "aws_ebs_volume" "wal" {
  count             = var.wal_volume_count
  availability_zone = var.availability_zone
  size              = var.wal_volume_size
  type              = "gp3"
  iops              = var.ebs_iops
  throughput        = var.ebs_throughput

  tags = {
    Name = "${var.project_name}-${var.node_name}-wal-${count.index}"
  }
}

resource "aws_volume_attachment" "wal" {
  count       = var.wal_volume_count
  device_name = "/dev/sd${element(["j", "k", "l", "m"], count.index)}"
  volume_id   = aws_ebs_volume.wal[count.index].id
  instance_id = aws_spot_instance_request.db.spot_instance_id
  force_detach = true
}

# Outputs
output "instance_id" {
  value = aws_spot_instance_request.db.spot_instance_id
}

output "public_ip" {
  value = aws_spot_instance_request.db.public_ip
}

output "private_ip" {
  value = aws_spot_instance_request.db.private_ip
}

output "data_volume_ids" {
  value = aws_ebs_volume.data[*].id
}

output "wal_volume_ids" {
  value = aws_ebs_volume.wal[*].id
}
