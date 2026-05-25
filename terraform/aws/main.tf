terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.28.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}



module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = var.vpc_name
  cidr = var.vpc_cidr_block

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway      = var.create_nat_gateway
  create_igw              = var.create_igw
  map_public_ip_on_launch = var.map_public_ip_on_launch
  single_nat_gateway      = var.single_nat_gateway

  tags = local.tags
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  count = var.enable_rds ? 1 : 0

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
  multi_az            = var.db_multi_az

  vpc_security_group_ids = [var.db_security_group_id]

  create_db_subnet_group = true
  subnet_ids             = module.vpc.private_subnets

  backup_retention_period = 7

  deletion_protection = true
  skip_final_snapshot = false

  auto_minor_version_upgrade = true

  tags = local.tags
}

resource "aws_ecr_repository" "clinic" {
  name                 = "clinic-appointment"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}
