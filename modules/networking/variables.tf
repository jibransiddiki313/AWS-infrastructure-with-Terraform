variable "project_name" {
  description = "Project ka naam (naming/tagging ke liye)"
  type        = string
}

variable "environment" {
  description = "Environment: dev / staging / prod"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "aws_region" {
  description = "AWS region (availability zones nikalne ke liye)"
  type        = string
}
