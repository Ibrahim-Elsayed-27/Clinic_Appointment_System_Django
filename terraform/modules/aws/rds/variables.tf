variable "db_identifier" {
  description = "An identifier for the RDS instance."
  type        = string
  default     = "demodb"
}

variable "db_engine" {
  description = "The database engine to use."
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "The version of the database engine."
  type        = string
  default     = "13.4"
}

variable "db_instance_class" {
  description = "The instance class for the RDS instance."
  type        = string
  default     = "db.t3a.large"
}


variable "db_allocated_storage" {
  description = "The allocated storage in gigabytes for the RDS instance."
  type        = number
  default     = 5
}

variable "db_name" {
  description = "The name of the database to create when the RDS instance is created."
  type        = string
  default     = "clinicdb"
}

variable "db_username" {
  description = "The master username for the RDS instance."
  type        = string
  default     = "user"
}


variable "db_port" {
  description = "The port on which the database accepts connections."
  type        = string
  default     = "5432"
}

variable "multi_az" {
  description = "Whether to create a Multi-AZ RDS instance for high availability."
  type        = bool
  default     = false
}

variable "db_security_group_id" {
  description = "The ID of the security group to associate with the RDS instance."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the RDS instance."
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to the RDS instance."
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "clinic-appointment"
  }
}

