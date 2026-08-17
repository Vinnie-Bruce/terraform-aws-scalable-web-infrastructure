locals {
  common_tags = {
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = "Lab"
  }
}