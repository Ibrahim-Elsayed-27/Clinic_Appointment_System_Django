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

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "create_igw" {
  description = "Whether the AWS VPC should create an Internet Gateway."
  type        = bool
  default     = false
}

variable "create_nat_gateway" {
  description = "Whether the AWS VPC should create a NAT Gateway for private subnets."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "clinic-appointment"
  }
}
