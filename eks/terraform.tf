terraform {
  required_version = "~> 1.2.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.18.0"
    }
  }
}

variable "AWS_REGION" {
  default = "eu-central-1"
}

provider "aws" {
  region = var.AWS_REGION
}