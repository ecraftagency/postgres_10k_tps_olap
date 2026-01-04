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

# Workaround: Tag the actual instance (spot request tags don't propagate)
resource "aws_ec2_tag" "postgres_name" {
  resource_id = aws_spot_instance_request.postgres.spot_instance_id
  key         = "Name"
  value       = "postgres-master"
}
