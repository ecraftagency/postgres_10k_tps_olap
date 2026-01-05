# =============================================================================
# Primary + Replica Topology Outputs
# =============================================================================

output "primary_public_ip" {
  value = module.primary.public_ip
}

output "primary_private_ip" {
  value = module.primary.private_ip
}

output "replica_public_ip" {
  value = module.replica.public_ip
}

output "replica_private_ip" {
  value = module.replica.private_ip
}

output "ssh_primary" {
  value = "ssh -i ${var.ssh_private_key} ubuntu@${module.primary.public_ip}"
}

output "ssh_replica" {
  value = "ssh -i ${var.ssh_private_key} ubuntu@${module.replica.public_ip}"
}

output "replication_primary_host" {
  description = "Use this IP for replica's primary_conninfo"
  value       = module.primary.private_ip
}
