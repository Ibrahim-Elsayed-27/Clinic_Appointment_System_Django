output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "internet_gateway_id" {
  description = "ID of the created Internet Gateway"
  value       = try(module.vpc.igw_id, null)
}

output "nat_gateway_id" {
  description = "ID of the created NAT Gateway"
  value       = try(module.vpc.natgw_ids[0], null)
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_route_table_ids" {
  description = "Public route table IDs"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "Private route table IDs"
  value       = module.vpc.private_route_table_ids
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint (null when RDS is disabled)"
  value       = var.enable_rds ? module.db[0].db_instance_endpoint : null
}

output "db_master_user_secret_arn" {
  description = "Secrets Manager ARN for RDS master credentials (null when RDS is disabled)"
  value       = var.enable_rds ? module.db[0].db_instance_master_user_secret_arn : null
}


output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_endpoint" {
  description = "EKS endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_ca_data" {
  description = "EKS certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "jenkins_instance_id" {
  description = "ID of the created Jenkins instance"
  value       = aws_instance.jenkins.id
}
