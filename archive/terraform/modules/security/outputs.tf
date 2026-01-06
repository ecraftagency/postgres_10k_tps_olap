# =============================================================================
# Security Module Outputs
# =============================================================================

output "shared_security_group_id" {
  description = "Shared security group ID"
  value       = aws_security_group.shared.id
}

output "shared_security_group_name" {
  description = "Shared security group name"
  value       = aws_security_group.shared.name
}
