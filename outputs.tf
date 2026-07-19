output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (where ASG instances run)"
  value       = module.networking.private_subnet_ids
}

output "app_url" {
  description = "Load balancer URL — open this in a browser to reach the app"
  value       = "http://${module.asg.alb_dns_name}"
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.asg.asg_name
}

output "ssm_role_name" {
  description = "IAM role name attached to instances (for SSM access)"
  value       = module.asg.iam_role_name
}

output "ssm_connect_hint" {
  description = "How to list running instances and connect via SSM (no SSH key needed)"
  value       = "aws ssm start-session --target <instance-id>   # get instance-id from: aws autoscaling describe-auto-scaling-instances"
}
