provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.5"
    }
  }

  backend "s3" {
    bucket = "tfbackendstate20240930"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

