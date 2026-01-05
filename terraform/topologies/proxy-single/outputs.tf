# =============================================================================
# Proxy + Single Node Topology Outputs
# =============================================================================

output "postgres_public_ip" {
  value = module.postgres.public_ip
}

output "postgres_private_ip" {
  value = module.postgres.private_ip
}

output "pgcat_public_ip" {
  value = module.pgcat.public_ip
}

output "pgcat_private_ip" {
  value = module.pgcat.private_ip
}

output "ssh_postgres" {
  value = "ssh -i ${var.ssh_private_key} ubuntu@${module.postgres.public_ip}"
}

output "ssh_pgcat" {
  value = "ssh -i ${var.ssh_private_key} ubuntu@${module.pgcat.public_ip}"
}

output "pgcat_config_postgres_host" {
  description = "Use this IP in PgCat config for PostgreSQL backend"
  value       = module.postgres.private_ip
}
