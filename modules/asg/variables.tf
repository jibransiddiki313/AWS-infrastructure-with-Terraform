variable "project_name" {
  description = "Project name (used for naming/tagging)"
  type        = string
}

variable "environment" {
  description = "Environment: dev / staging / prod"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type used in the launch template"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ASG, ALB and security groups will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "asg_subnet_ids" {
  description = "List of subnet IDs where ASG instances will launch"
  type        = list(string)
}

variable "your_ip_cidr" {
  description = "IP CIDR allowed to SSH (not used when key_name is empty, kept for future use)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_name" {
  description = "Existing AWS key pair name (leave empty to rely only on SSM access)"
  type        = string
  default     = ""
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 2
}

variable "app_port" {
  description = "Port the application listens on inside each instance"
  type        = number
  default     = 3000
}
