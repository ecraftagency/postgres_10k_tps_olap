# =============================================================================
# PostgreSQL Master Instance (On-Demand)
# =============================================================================

resource "aws_instance" "postgres" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.shared.id]
  subnet_id              = aws_subnet.public.id

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "postgres-master"
  }
}

resource "aws_ebs_volume" "pg_data" {
  count             = var.pg_data_volume_count
  availability_zone = var.az
  size              = var.pg_data_volume_size
  type              = "gp3"

  tags = {
    Name = "pg-data-${count.index}"
    Role = "data"
  }
}

resource "aws_ebs_volume" "pg_wal" {
  count             = var.pg_wal_volume_count
  availability_zone = var.az
  size              = var.pg_wal_volume_size
  type              = "gp3"

  tags = {
    Name = "pg-wal-${count.index}"
    Role = "wal"
  }
}

resource "aws_volume_attachment" "pg_data" {
  count       = var.pg_data_volume_count
  device_name = "/dev/sd${element(["f", "g", "h", "i", "j", "k", "l", "m"], count.index)}"
  volume_id   = aws_ebs_volume.pg_data[count.index].id
  instance_id = aws_instance.postgres.id
}

resource "aws_volume_attachment" "pg_wal" {
  count       = var.pg_wal_volume_count
  device_name = "/dev/sd${element(["n", "o", "p", "q", "r", "s", "t", "u"], count.index)}"
  volume_id   = aws_ebs_volume.pg_wal[count.index].id
  instance_id = aws_instance.postgres.id
}
