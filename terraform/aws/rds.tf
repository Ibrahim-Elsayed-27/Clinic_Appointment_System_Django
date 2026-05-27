# ── RDS ────────────────────────────────────────────────────────
resource "aws_security_group" "rds" {
  count = var.enable_rds ? 1 : 0

  name        = "${var.environment}-clinic-rds-sg"
  description = "Allow PostgreSQL from EKS nodes only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  count = var.enable_rds ? 1 : 0

  identifier        = var.db_identifier
  family            = var.db_family
  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  port     = var.db_port

  manage_master_user_password = true

  publicly_accessible = false
  multi_az            = var.db_multi_az

  vpc_security_group_ids = [aws_security_group.rds[0].id]

  create_db_subnet_group = true
  subnet_ids             = module.vpc.private_subnets

  backup_retention_period = 7
  deletion_protection     = true
  skip_final_snapshot     = false

  auto_minor_version_upgrade = true

  tags = local.tags
}
