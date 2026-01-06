# =============================================================================
# PostgreSQL Node Module Outputs
# =============================================================================

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_spot_instance_request.postgres.spot_instance_id
}

output "spot_request_id" {
  description = "Spot instance request ID"
  value       = aws_spot_instance_request.postgres.id
}

output "public_ip" {
  description = "Public IP address"
  value       = aws_spot_instance_request.postgres.public_ip
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_spot_instance_request.postgres.private_ip
}

output "public_dns" {
  description = "Public DNS name"
  value       = aws_spot_instance_request.postgres.public_dns
}

output "private_dns" {
  description = "Private DNS name"
  value       = aws_spot_instance_request.postgres.private_dns
}
