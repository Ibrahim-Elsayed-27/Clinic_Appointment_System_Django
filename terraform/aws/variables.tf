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
  default     = true
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
  default = [
    "arn:aws:secretsmanager:*:*:secret:clinic/*"
  ]
}

variable "enable_private_api_endpoints" {
  description = "Create interface VPC endpoints so private resources can reach AWS APIs without NAT"
  type        = bool
  default     = false
}

variable "enable_alb_controller_irsa" {
  description = "Create IRSA IAM role for AWS Load Balancer Controller (required for ALB Ingress)"
  type        = bool
  default     = true
}

variable "create_ecr" {
  description = "Create ECR"
  type        = bool
  default     = false
}

variable "enable_eks_endpoint_public_access" {
  description = "Enable public access to EKS endpoints"
  type        = bool
  default     = false
}

variable "enable_eks_bootstrap_cluster_creator_admin_permissions" {
  description = "Grant cluster creator admin permissions at bootstrap time for EKS access entries"
  type        = bool
  default     = false
}


variable "bastion_allowed_cidrs" {
  description = "List of CIDRs allowed to SSH to bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}


# Per-endpoint toggles (allow enabling each VPC endpoint independently)
variable "enable_endpoint_s3" {
  description = "Enable S3 VPC endpoint"
  type        = bool
  default     = false
}

variable "enable_endpoint_ecr_api" {
  description = "Enable ECR API VPC endpoint"
  type        = bool
  default     = false
}

variable "enable_endpoint_ecr_dkr" {
  description = "Enable ECR DKR VPC endpoint"
  type        = bool
  default     = false
}

variable "enable_endpoint_ec2" {
  description = "Enable EC2 VPC endpoint"
  type        = bool
  default     = false
}

variable "enable_endpoint_sts" {
  description = "Enable STS VPC endpoint"
  type        = bool
  default     = false
}

variable "enable_endpoint_eks" {
  description = "Enable EKS VPC endpoint"
  type        = bool
  default     = false
}

variable "enable_endpoint_secretsmanager" {
  description = "Enable Secrets Manager VPC endpoint"
  type        = bool
  default     = false
}

variable "enable_endpoint_ssm" {
  description = "Enable SSM VPC endpoint"
  type        = bool
  default     = false
}

variable "enable_endpoint_ssmmessages" {
  description = "Enable SSM Messages VPC endpoint"
  type        = bool
  default     = false
}

variable "enable_endpoint_ec2messages" {
  description = "Enable EC2 Messages VPC endpoint"
  type        = bool
  default     = false
}
