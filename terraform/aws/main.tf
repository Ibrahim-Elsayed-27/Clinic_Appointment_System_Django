terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source               = "../modules/aws/vpc"
  name                 = var.vpc_name
  cidr_block           = var.vpc_cidr_block
  create_igw           = var.create_igw
  create_nat_gateway   = var.create_nat_gateway
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = var.tags
}
