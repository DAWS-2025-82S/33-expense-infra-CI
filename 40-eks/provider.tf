terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.95.0"
    }
  }

  backend "s3" {
    bucket = "terraform-82s-statefile-dev"
    key    = "expense-dev-eks-eks-pipeline" # you should have unique keys with in the bucket, same key should not be used in other repos or tf projects
    region = "us-east-1"
    dynamodb_table = "82s-state-locking-dev"
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}