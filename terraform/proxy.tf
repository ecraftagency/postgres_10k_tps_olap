# =============================================================================
# PgCat Connection Pooler Proxy
# =============================================================================
# Lightweight instance for PgCat connection pooling
# Connects to PostgreSQL via TCP (private network)
# Exposes Unix socket for local benchmark clients
# =============================================================================

variable "proxy_instance_type" {
  description = "Instance type for proxy"
  default     = "c8g.2xlarge"
}

variable "proxy_enabled" {
  description = "Whether to create proxy instance"
  default     = true
}

resource "aws_spot_instance_request" "proxy" {
  count                  = var.proxy_enabled ? 1 : 0
  ami                    = var.ami
  instance_type          = var.proxy_instance_type
  spot_price             = "0.15"
  wait_for_fulfillment   = true
  spot_type              = "one-time"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.shared.id]
  subnet_id              = aws_subnet.public.id

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "pgcat-proxy"
  }
}

# =============================================================================
# Outputs
# =============================================================================

output "proxy_public_ip" {
  value = var.proxy_enabled ? aws_spot_instance_request.proxy[0].public_ip : null
}

output "proxy_private_ip" {
  value = var.proxy_enabled ? aws_spot_instance_request.proxy[0].private_ip : null
}

output "proxy_instance_id" {
  value = var.proxy_enabled ? aws_spot_instance_request.proxy[0].spot_instance_id : null
}

output "proxy_ssh_command" {
  value = var.proxy_enabled ? "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_spot_instance_request.proxy[0].public_ip}" : null
}

output "postgres_private_ip_for_pgcat" {
  value       = aws_spot_instance_request.postgres.private_ip
  description = "Use this IP in PgCat config"
}
