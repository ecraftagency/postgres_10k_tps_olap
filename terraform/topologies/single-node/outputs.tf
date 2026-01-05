# =============================================================================
# Single Node Topology Outputs
# =============================================================================

output "postgres_public_ip" {
  description = "PostgreSQL public IP"
  value       = module.postgres.public_ip
}

output "postgres_private_ip" {
  description = "PostgreSQL private IP"
  value       = module.postgres.private_ip
}

output "postgres_instance_id" {
  description = "PostgreSQL instance ID"
  value       = module.postgres.instance_id
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i ${var.ssh_private_key} ubuntu@${module.postgres.public_ip}"
}

output "rsync_command" {
  description = "Rsync command to deploy scripts"
  value       = "rsync -avz -e \"ssh -i ${var.ssh_private_key}\" scripts2/ ubuntu@${module.postgres.public_ip}:/home/ubuntu/scripts2/"
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "subnet_id" {
  description = "Public subnet ID"
  value       = module.network.public_subnet_id
}
