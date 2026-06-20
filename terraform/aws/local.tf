locals {
  name_prefix = "${var.environment}-clinic-appointment"

  tags = {
    Project     = "clinic-appointment"
    Environment = var.environment
    ManagedBy   = "terraform"
    CreatedBy   = "terraform"
  }
}
