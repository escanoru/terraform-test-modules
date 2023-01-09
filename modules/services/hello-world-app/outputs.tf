output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "The domain name of the load balancer"
}

output "asg_name" {
  value       = module.asg.asg_name
  description = "The name of the Auto Scaling Group"
}

output "instance_security_group_id" {
  value       = module.asg.instance_security_group_id
  description = "The ID of the EC2 Instance Security Group"
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

output "autoscaling_config" {
  value       = var.enable_autoscaling
  description = "Autoscaling configuration"
}