output "instance_id" {
  description = "The identifier of the RDS instance."
  value       = module.db.db_instance_identifier
}

output "instance_endpoint" {
  description = "RDS instance endpoint."
  value       = module.db.db_instance_endpoint
}

output "instance_address" {
  description = "RDS instance hostname."
  value       = module.db.db_instance_address
}

output "instance_port" {
  description = "RDS instance port."
  value       = module.db.db_instance_port
}

output "instance_arn" {
  description = "RDS instance ARN."
  value       = module.db.db_instance_arn
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN containing DB credentials."
  value       = module.db.db_instance_master_user_secret_arn
}
