terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

// The first step in creating an ASG is to create a launch configuration, which specifies how to configure each EC2 Instance in the ASG.
resource "aws_launch_configuration" "example" {
  image_id         = var.ami
  instance_type    = var.instance_type
  security_groups  = [aws_security_group.instance.id]
  user_data        = var.user_data
  
  # Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = true

    // We add a precondition block to the aws_launch_configuration resource to check that the instance type passed to instance_type is eligible for the AWS Free Tier:
    precondition {
      condition     = data.aws_ec2_instance_type.instance.free_tier_eligible
      error_message = "${var.instance_type} is not part of the AWS Free Tier!"
    }
  }
}

// Now you can create the ASG itself using the aws_autoscaling_group resource:
resource "aws_autoscaling_group" "example" {
  name = var.cluster_name
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = var.subnet_ids

  # Configure integrations with a load balancer
  target_group_arns    = var.target_group_arns
  health_check_type    = var.health_check_type

  // This ASG will run between 2 and 10 EC2 Instances (defaulting to 2 for the initial launch)
  min_size = var.min_size
  desired_capacity = var.desired_capacity
  max_size = var.max_size

  # Use instance refresh to roll out changes to the ASG
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  lifecycle {
    postcondition {
      condition     = length(self.availability_zones) > 1
      error_message = "You must use more than one AZ for high availability!"
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name} ASG conf"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.custom_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name  = "${var.cluster_name}-scale-out-during-business-hours"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 10
  recurrence             = "0 9 * * *"
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name  = "${var.cluster_name}-scale-in-at-night"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 2
  recurrence             = "0 17 * * *"
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_security_group" "instance" {
  name = "${var.cluster_name} ASG"
  description = "${var.cluster_name} ASG security group"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.cluster_name} ASG"
  }
}

resource "aws_security_group_rule" "instance_allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}
