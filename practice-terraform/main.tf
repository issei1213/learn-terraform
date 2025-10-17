# --------------------------------
# Terraform configuration
# --------------------------------
terraform {
  required_version = ">=1.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = "~>6.15"
    }
  }
}

# --------------------------------
# Provider
# --------------------------------
provider "aws" {
  profile = "terraform"
  region  = "ap-northeast-1"
}

module "example_sg" {
  source      = "./security_group"
  name        = "module-sg"
  vpc_id      = aws_vpc.example.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}
