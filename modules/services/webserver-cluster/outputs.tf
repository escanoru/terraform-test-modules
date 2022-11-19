output "asg_name" {
  value       = aws_autoscaling_group.asg_conf.name
  description = "The name of the Auto Scaling Group"
}

output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "The domain name of the load balancer"
}

output "alb_security_group_id" {
  value       = aws_security_group.alb_sg.id
  description = "The ID of the Security Group attached to the load balancer"
}

output "default_vpc_id" {
  value       = data.aws_vpc.default.id
  description = "The default VPC id"
}

output "default_vpc_available_subnets" {
  value       = data.aws_subnets.default.ids
  description = "The available subnets on the default VPC"
}
