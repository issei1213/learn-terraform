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

# --------------------------------
# Variables
# --------------------------------
variable "project" {
  type = string
}

variable "environment" {
  type = string
}
