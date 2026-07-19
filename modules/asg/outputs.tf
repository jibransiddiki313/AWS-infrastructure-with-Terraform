output "alb_dns_name" {
  description = "Public DNS name of the load balancer — this is your app URL"
  value       = aws_lb.app.dns_name
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "iam_role_name" {
  description = "IAM role name attached to instances (for SSM access)"
  value       = aws_iam_role.ssm_role.name
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.app.arn
}

output "instance_security_group_id" {
  description = "Security group ID attached to ASG instances"
  value       = aws_security_group.instance_sg.id
}
