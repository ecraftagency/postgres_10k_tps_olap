# =============================================================================
# PostgreSQL Node Module
# =============================================================================
# Provisions a PostgreSQL instance with optional EBS volumes for RAID
# Supports both fresh instances and AMI-based restoration
# =============================================================================

locals {
  # Device names for data volumes (/dev/sdf through /dev/sdm)
  data_device_letters = ["f", "g", "h", "i", "j", "k", "l", "m"]
  # Device names for WAL volumes (/dev/sdn through /dev/sdu)
  wal_device_letters  = ["n", "o", "p", "q", "r", "s", "t", "u"]
}

# =============================================================================
# EC2 Spot Instance
# =============================================================================

resource "aws_spot_instance_request" "postgres" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  spot_price             = var.spot_price
  wait_for_fulfillment   = true
  spot_type              = "one-time"
  key_name               = var.key_name
  vpc_security_group_ids = [var.security_group_id]
  subnet_id              = var.subnet_id

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # Data volumes (for RAID10)
  dynamic "ebs_block_device" {
    for_each = var.create_ebs_volumes ? range(var.data_disk_count) : []
    content {
      device_name           = "/dev/sd${local.data_device_letters[ebs_block_device.value]}"
      volume_size           = var.data_disk_size
      volume_type           = "gp3"
      iops                  = var.data_disk_iops
      throughput            = var.data_disk_throughput
      delete_on_termination = var.delete_volumes_on_termination
    }
  }

  # WAL volumes (for RAID10)
  dynamic "ebs_block_device" {
    for_each = var.create_ebs_volumes ? range(var.wal_disk_count) : []
    content {
      device_name           = "/dev/sd${local.wal_device_letters[ebs_block_device.value]}"
      volume_size           = var.wal_disk_size
      volume_type           = "gp3"
      iops                  = var.wal_disk_iops
      throughput            = var.wal_disk_throughput
      delete_on_termination = var.delete_volumes_on_termination
    }
  }

  tags = {
    Name = var.node_name
    Role = var.node_role
  }
}

# Tag the actual instance (spot request tags don't propagate)
resource "aws_ec2_tag" "name" {
  resource_id = aws_spot_instance_request.postgres.spot_instance_id
  key         = "Name"
  value       = var.node_name
}

resource "aws_ec2_tag" "role" {
  resource_id = aws_spot_instance_request.postgres.spot_instance_id
  key         = "Role"
  value       = var.node_role
}

# =============================================================================
# Set DeleteOnTermination for AMI-based volumes
# =============================================================================
# When restoring from AMI, volumes don't inherit delete_on_termination
# This ensures cleanup on instance termination

resource "null_resource" "set_volume_delete_on_termination" {
  count      = var.set_delete_on_termination ? 1 : 0
  depends_on = [aws_spot_instance_request.postgres]

  provisioner "local-exec" {
    command = <<-EOT
      INSTANCE_ID="${aws_spot_instance_request.postgres.spot_instance_id}"

      aws ec2 describe-instances --instance-ids $INSTANCE_ID --region ${var.region} \
        --query 'Reservations[].Instances[].BlockDeviceMappings[].{Device:DeviceName,Volume:Ebs.VolumeId}' \
        --output text | while read device volume; do
          echo "Setting DeleteOnTermination=true for $volume ($device)"
          aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --region ${var.region} \
            --block-device-mappings "[{\"DeviceName\":\"$device\",\"Ebs\":{\"DeleteOnTermination\":true}}]"
        done
    EOT
  }
}
