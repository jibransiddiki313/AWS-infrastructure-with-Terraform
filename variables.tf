variable "aws_region" {
  description = "AWS region to deploy into (e.g. ap-south-1)"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name, used for naming and tagging all resources"
  type        = string
  default     = "aws-infra-automation"
}

variable "owner_name" {
  description = "Resource owner name (for tagging)"
  type        = string
  default     = "your-name"
}

variable "environment" {
  description = "Environment: dev / staging / prod"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type used by the Auto Scaling Group"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Existing AWS key pair name (leave empty to rely only on SSM access)"
  type        = string
  default     = ""
}

variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 3000
}

variable "asg_min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
  default     = 2
}
