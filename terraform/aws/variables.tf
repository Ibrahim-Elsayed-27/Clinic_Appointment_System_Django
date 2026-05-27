variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment for all resources"
  type        = string
  default     = "dev"
}

variable "availability_zones" {
  description = "Availability zones used by subnets."
  type        = list(string)
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "clinic-appointment-vpc"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "map_public_ip_on_launch" {
  description = "Whether to map public IP on launch"
  type        = bool
  default     = false
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "create_igw" {
  description = "Whether the VPC should create an Internet Gateway"
  type        = bool
  default     = false
}

variable "create_nat_gateway" {
  description = "Whether the VPC should create a NAT Gateway for private subnets"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Whether the VPC should create a single NAT Gateway for private subnets"
  type        = bool
  default     = false
}

variable "node_instance_type" {
  description = "EKS managed node group instance type"
  type        = string
  default     = "t3.medium"
}

variable "node_min_size" {
  description = "EKS managed node group minimum size"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "EKS managed node group maximum size"
  type        = number
  default     = 2
}

variable "node_desired_size" {
  description = "EKS managed node group desired size"
  type        = number
  default     = 1
}

variable "enable_rds" {
  description = "Create RDS instance (requires db_security_group_id)"
  type        = bool
  default     = false
}

variable "db_identifier" {
  description = "RDS instance identifier"
  type        = string
  default     = "clinic-db"
}

variable "db_family" {
  type    = string
  default = "postgres16"
}

variable "db_engine" {
  description = "RDS database engine"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "RDS engine version"
  type        = string
  default     = "16.4"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage (GB)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "clinicdb"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "clinicadmin"
}

variable "db_port" {
  description = "RDS port"
  type        = number
  default     = 5432
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

variable "jenkins_secret_arns" {
  description = "Secrets Manager ARNs Jenkins is allowed to read"
  type        = list(string)
  default     = ["*"]
}

variable "enable_private_api_endpoints" {
  description = "Create interface VPC endpoints so private resources can reach AWS APIs without NAT"
  type        = bool
  default     = true
}
