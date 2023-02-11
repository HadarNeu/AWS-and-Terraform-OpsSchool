provider "aws" {
  region = var.aws_region
}

terraform {
  cloud {
    organization = "hadar-organization"
    workspaces {
      name = "AWS-and-Terraform-OpsSchool"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.30.0"
    }
  }
  required_version = "~> 1.0"
}
