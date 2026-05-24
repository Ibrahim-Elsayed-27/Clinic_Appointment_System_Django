output "vpc_id" {
  description = "ID of the created VPC."
  value       = module.vpc.vpc_id
}

output "internet_gateway_id" {
  description = "ID of the created Internet Gateway."
  value       = try(module.vpc.igw_id, null)
}

output "nat_gateway_id" {
  description = "ID of the created NAT Gateway."
  value       = try(module.vpc.natgw_ids[0], null)
}

output "public_subnet_ids" {
  description = "IDs of created public subnets."
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of created private subnets."
  value       = module.vpc.private_subnets
}

output "public_route_table_ids" {
  description = "Public route table IDs."
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "Private route table IDs."
  value       = module.vpc.private_route_table_ids
}
