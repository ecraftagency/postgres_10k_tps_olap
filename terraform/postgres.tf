# =============================================================================
# PostgreSQL Master Instance (Spot)
# =============================================================================
# Restored from AMI with pre-configured RAID10 volumes
# AMI includes: 8x data volumes + 8x WAL volumes from snapshots
# =============================================================================

resource "aws_spot_instance_request" "postgres" {
  ami                    = var.db_ami
  instance_type          = var.instance_type
  spot_price             = "1.50"
  wait_for_fulfillment   = true
  spot_type              = "one-time"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.shared.id]
  subnet_id              = aws_subnet.public.id

  tags = {
    Name = "postgres-master"
  }
}

# Tag the actual instance (spot request tags don't propagate)
resource "aws_ec2_tag" "postgres_name" {
  resource_id = aws_spot_instance_request.postgres.spot_instance_id
  key         = "Name"
  value       = "postgres-master"
}

# Set delete_on_termination=true for all volumes after instance launch
resource "null_resource" "set_volume_delete_on_termination" {
  depends_on = [aws_spot_instance_request.postgres]

  provisioner "local-exec" {
    command = <<-EOT
      INSTANCE_ID="${aws_spot_instance_request.postgres.spot_instance_id}"

      # Get all block device mappings and set delete_on_termination
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
