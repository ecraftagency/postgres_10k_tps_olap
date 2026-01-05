# =============================================================================
# PgCat Node Module Outputs
# =============================================================================

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_spot_instance_request.pgcat.spot_instance_id
}

output "public_ip" {
  description = "Public IP address"
  value       = aws_spot_instance_request.pgcat.public_ip
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_spot_instance_request.pgcat.private_ip
}
