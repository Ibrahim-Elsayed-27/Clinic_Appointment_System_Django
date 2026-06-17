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


resource "aws_security_group" "private_api_endpoints" {
  name        = "${local.tags.Project}-private-api-endpoints-sg"
  description = "Allow HTTPS from VPC resources to interface endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 6.0"

  create             = var.enable_private_api_endpoints
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.private_api_endpoints.id]

  tags = local.tags

  endpoints = {

    # Gateway endpoint
    s3 = {
      create          = var.enable_private_api_endpoints && var.enable_endpoint_s3
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
    }

    # ECR
    ecr_api = {
      create              = var.enable_private_api_endpoints && var.enable_endpoint_ecr_api
      service             = "ecr.api"
      private_dns_enabled = true
    }

    ecr_dkr = {
      create              = var.enable_private_api_endpoints && var.enable_endpoint_ecr_dkr
      service             = "ecr.dkr"
      private_dns_enabled = true
    }

    # AWS APIs commonly used by EKS/Jenkins
    ec2 = {
      create              = var.enable_private_api_endpoints && var.enable_endpoint_ec2
      service             = "ec2"
      private_dns_enabled = true
    }

    sts = {
      create              = var.enable_private_api_endpoints && var.enable_endpoint_sts
      service             = "sts"
      private_dns_enabled = true
    }

    eks = {
      create              = var.enable_private_api_endpoints && var.enable_endpoint_eks
      service             = "eks"
      private_dns_enabled = true
    }

    # Secrets Manager
    secretsmanager = {
      create              = var.enable_private_api_endpoints && var.enable_endpoint_secretsmanager
      service             = "secretsmanager"
      private_dns_enabled = true
    }

    # Session Manager
    ssm = {
      create              = var.enable_private_api_endpoints && var.enable_endpoint_ssm
      service             = "ssm"
      private_dns_enabled = true
    }

    ssmmessages = {
      create              = var.enable_private_api_endpoints && var.enable_endpoint_ssmmessages
      service             = "ssmmessages"
      private_dns_enabled = true
    }

    ec2messages = {
      create              = var.enable_private_api_endpoints && var.enable_endpoint_ec2messages
      service             = "ec2messages"
      private_dns_enabled = true
    }
  }
}
