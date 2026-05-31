# ── VPC ────────────────────────────────────────────────────────
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

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 6.0"

  create             = true
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.private_api_endpoints.id]
  tags               = local.tags

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
    }
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.private_api_endpoints.id]
    }
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.private_api_endpoints.id]
    }
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.private_api_endpoints.id]
    }
    sts = {
      service             = "sts"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.private_api_endpoints.id]
    }
  }
}
