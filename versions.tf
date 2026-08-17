terraform {

  required_version = ">=1.15.8"

  backend "s3" {
    bucket = "vinnie-tf-state-foundations-12345"
    key = "projects/private-multi-az-app/lab/terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.60.0"
    }
  }
}