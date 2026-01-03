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
  value = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_spot_instance_request.postgres.public_ip}"
}

output "data_volumes" {
  value = [for v in aws_ebs_volume.pg_data : v.id]
}

output "wal_volumes" {
  value = [for v in aws_ebs_volume.pg_wal : v.id]
}
