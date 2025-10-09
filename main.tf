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
  backend "s3" {
    bucket  = "tastylog-tfstate-bucket-issei1213"
    key     = "tastylog-dev.tfstate"
    region  = "ap-northeast-1"
    profile = "terraform"
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
