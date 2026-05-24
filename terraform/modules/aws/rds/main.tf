module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = var.db_identifier

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
  multi_az            = var.multi_az

  vpc_security_group_ids = [var.db_security_group_id]

  create_db_subnet_group = true
  subnet_ids             = var.private_subnet_ids

  backup_retention_period = 7

  deletion_protection = true
  skip_final_snapshot = false

  auto_minor_version_upgrade = true

  tags = var.tags
}
