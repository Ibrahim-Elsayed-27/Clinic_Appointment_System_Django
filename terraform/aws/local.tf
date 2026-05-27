locals {
  tags = {
    Project     = "clinic-appointment"
    Environment = var.environment
    ManagedBy   = "terraform"
    CreatedBy   = "terraform"
  }
}
