terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
   shared_config_files      = ["~/.aws/config"]
   shared_credentials_files = ["~/.aws/credentials"]
}

output "ip_addresses" {
   value = ["${aws_instance.webserver.*.public_ip}"]
}
