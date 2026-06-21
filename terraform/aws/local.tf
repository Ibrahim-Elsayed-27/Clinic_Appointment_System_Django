locals {
  name_prefix = "$clinic-appointment"

  tags = {
    Project   = "clinic-appointment"
    ManagedBy = "terraform"
    CreatedBy = "terraform"
  }
}
