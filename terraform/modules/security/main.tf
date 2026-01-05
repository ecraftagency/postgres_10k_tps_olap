# =============================================================================
# Security Module - Security Groups
# =============================================================================

resource "aws_security_group" "shared" {
  name        = "${var.project}-shared-sg"
  description = "Shared security group for all nodes"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
    description = "SSH access"
  }

  # PostgreSQL access (optional, from specific CIDRs)
  dynamic "ingress" {
    for_each = var.postgres_access_enabled ? [1] : []
    content {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = var.postgres_cidr_blocks
      description = "PostgreSQL access"
    }
  }

  # PgCat access (optional)
  dynamic "ingress" {
    for_each = var.pgcat_access_enabled ? [1] : []
    content {
      from_port   = 6432
      to_port     = 6432
      protocol    = "tcp"
      cidr_blocks = var.pgcat_cidr_blocks
      description = "PgCat pooler access"
    }
  }

  # Internal communication (all nodes can talk to each other)
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
    description = "Internal cluster communication"
  }

  # Outbound - allow all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project}-shared-sg"
  }
}
