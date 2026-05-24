variable "name" {
  description = "Base name for VPC resources."
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "create_igw" {
  description = "Whether to create an Internet Gateway for the VPC."
  type        = bool
  default     = false
}

variable "create_nat_gateway" {
  description = "Whether to create a NAT Gateway for private subnets."
  type        = bool
  default     = false
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.0.2.0/24"]
}


variable "tags" {
  description = "Tags applied to created VPC resources."
  type        = map(string)
  default     = {}
}
