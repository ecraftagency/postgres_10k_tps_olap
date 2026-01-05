# =============================================================================
# PgCat Connection Pooler Node Module
# =============================================================================
# Lightweight instance for PgCat/PgBouncer connection pooling
# =============================================================================

resource "aws_spot_instance_request" "pgcat" {
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

  tags = {
    Name = var.node_name
    Role = "proxy"
  }
}

# Tag the actual instance
resource "aws_ec2_tag" "name" {
  resource_id = aws_spot_instance_request.pgcat.spot_instance_id
  key         = "Name"
  value       = var.node_name
}
