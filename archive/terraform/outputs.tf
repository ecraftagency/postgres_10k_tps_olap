# =============================================================================
# Outputs - Also saved to local file for persistence
# =============================================================================

output "postgres_public_ip" {
  value = aws_spot_instance_request.postgres.public_ip
}

output "postgres_private_ip" {
  value = aws_spot_instance_request.postgres.private_ip
}

output "postgres_instance_id" {
  value = aws_spot_instance_request.postgres.spot_instance_id
}

output "ssh_command" {
  value = "ssh -i ${var.ssh_private_key} ubuntu@${aws_spot_instance_request.postgres.public_ip}"
}

output "rsync_command" {
  value = "rsync -avz -e \"ssh -i ${var.ssh_private_key}\" scripts/ ubuntu@${aws_spot_instance_request.postgres.public_ip}:/home/ubuntu/scripts/"
}

# =============================================================================
# Save outputs to local file for context recovery
# =============================================================================

resource "local_file" "connection_info" {
  content = jsonencode({
    postgres_public_ip  = aws_spot_instance_request.postgres.public_ip
    postgres_private_ip = aws_spot_instance_request.postgres.private_ip
    postgres_instance_id = aws_spot_instance_request.postgres.spot_instance_id
    ssh_command         = "ssh -i ${var.ssh_private_key} ubuntu@${aws_spot_instance_request.postgres.public_ip}"
    rsync_command       = "rsync -avz -e \"ssh -i ${var.ssh_private_key}\" scripts/ ubuntu@${aws_spot_instance_request.postgres.public_ip}:/home/ubuntu/scripts/"
    instance_type       = var.instance_type
    created_at          = timestamp()
  })
  filename = "${path.module}/connection.json"
}
