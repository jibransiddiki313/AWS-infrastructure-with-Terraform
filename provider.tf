terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote backend (S3 + DynamoDB state locking) — uncomment and fill in your values
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "aws-infra-automation/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "terraform"
      Owner       = var.owner_name
      Environment = var.environment
    }
  }
}
