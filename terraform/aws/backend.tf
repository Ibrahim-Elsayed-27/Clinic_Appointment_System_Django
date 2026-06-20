terraform {
  backend "s3" {
    bucket               = "clinic-appointment-terraform"
    key                  = "terraform.tfstate"
    region               = "us-east-1"
    workspace_key_prefix = "envs"
  }
}
