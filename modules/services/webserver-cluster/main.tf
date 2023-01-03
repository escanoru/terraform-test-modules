provider "aws" {
  region = var.aws_region
}

locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

/*
The first step in creating an ASG is to create a launch configuration, which specifies how to configure each EC2 Instance in the ASG.
The aws_launch_configuration resource uses almost the same parameters as the aws_instance resource, although it doesn’t support tags (you’ll handle these in the aws_autoscaling_group resource later) or the user_data_replace_on_change parameter (ASGs launch new instances by default, so you don’t need this parameter), and two of the parameters have different names (ami is now image_id and vpc_security_group_ids is now security_groups), so replace aws_instance with aws_launch_configuration as follows:
*/

resource "aws_launch_configuration" "asg_lc" {
  image_id        = "ami-08d4ac5b634553e16"
  instance_type   = var.instance_type
  security_groups = [aws_security_group.asg_sg.id]

  // https://developer.hashicorp.com/terraform/language/functions/templatefile
  user_data = templatefile("${path.module}/user-data.sh", {
    server_port       = var.server_port
    db_address        = data.terraform_remote_state.db.outputs.rds_mysql_address
    db_port           = data.terraform_remote_state.db.outputs.rds_mysql_port
    db_engine         = data.terraform_remote_state.db.outputs.rds_mysql_engine
    db_engine_version = data.terraform_remote_state.db.outputs.rds_mysql_engine_version
  })
  
  /*
  Note that the aws_autoscaling_group resource uses a reference to fill in the launch configuration name. This leads to a problem: launch configurations are immutable, so if you change any parameter of your launch configuration, Terraform will try to replace it. Normally, when replacing a resource, Terraform deletes the old resource first and then creates its replacement, but because your ASG now has a reference to the old resource, Terraform won’t be able to delete it.
  To solve this problem, you can use a lifecycle setting. Every Terraform resource supports several lifecycle settings that configure how that resource is created, updated, and/or deleted. A particularly useful lifecycle setting is create_before_destroy. If you set create_before_destroy to true, Terraform will invert the order in which it replaces resources, creating the replacement resource first (including updating any references that were pointing at the old resource to point to the replacement) and then deleting the old resource
  */
  lifecycle {
    create_before_destroy = true
  }

}

// Now you can create the ASG itself using the aws_autoscaling_group resource:
resource "aws_autoscaling_group" "asg_conf" {
  launch_configuration = aws_launch_configuration.asg_lc.name
  /*
  There’s also one other parameter that you need to add to your ASG to make it work: subnet_ids. 
  This parameter specifies to the ASG into which VPC subnets the EC2 Instances should be deployed
  Each subnet lives in an isolated AWS AZ (that is, an isolated datacenter), so by deploying your Instances across multiple subnets, you ensure that your service can keep running even if some of the datacenters have an outage. You could hardcode the list of subnets, but that won’t be maintainable or portable, so a better option is to use data sources to get the list of subnets in your AWS account, we perform this on the aws_vpc and aw_subnets data source blocks
  Finally, you can pull the subnet IDs out of the aws_subnets data source and tell your ASG to use those subnets via the (somewhat oddly named) vpc_zone_identifier argument:
  */
  vpc_zone_identifier  = data.aws_subnets.default.ids
  target_group_arns = [aws_lb_target_group.alb_target_group.arn]


  /*
  You should also update the health_check_type to "ELB". The default health_check_type is "EC2", which is a minimal health check that considers an Instance unhealthy only if the AWS hypervisor says the VM is completely down or unreachable. The "ELB" health check is more robust, because it instructs the ASG to use the target group’s health check to determine whether an Instance is healthy and to automatically replace Instances if the target group reports them as unhealthy. That way, instances will be replaced not only if they are completely down, but also if, for example, they’ve stopped serving requests because they ran out of memory or a critical process crashed:
  */
  health_check_type = "ELB"

  // This ASG will run between 2 and 10 EC2 Instances (defaulting to 2 for the initial launch)
  min_size = var.min_size
  desired_capacity = var.desired_capacity
  max_size = var.max_size

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

resource "aws_security_group" "asg_sg" {
  name = "${var.cluster_name}-asg-sg"
  description = "${var.cluster_name} ASG security group"
  vpc_id = data.aws_vpc.default.id

  tags = {
    Name = "${var.cluster_name} ASG security group"
  }
}

resource "aws_security_group_rule" "asg_sg_allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.asg_sg.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

/*
At this point, you can deploy your ASG, but you’ll have a small problem: you now have multiple servers, each with its own IP address, but you typically want to give your end users only a single IP to use. One way to solve this problem is to deploy a load balancer to distribute traffic across your servers and to give all your users the IP (actually, the DNS name) of the load balancer.
*/

// The first step is to create the ALB itself using the aws_lb resource:
resource "aws_lb" "alb" {
  name               = "${var.cluster_name}-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  /*
  Note that the subnets parameter configures the load balancer to use all the subnets in your Default VPC by using the aws_subnets data source. AWS load balancers don’t consist of a single server, but multiple servers that can run in separate subnets (and therefore, separate datacenters). AWS automatically scales the number of load balancer servers up and down based on traffic and handles failover if one of those servers goes down, so you get scalability and high availability out of the box.
  */

  /*
  Note that, by default, all AWS resources, including ALBs, don’t allow any incoming or outgoing traffic, so you need to create a new security group specifically for the ALB. This security group should allow incoming requests on port 80 so that you can access the load balancer over HTTP, and outgoing requests on all ports so that the load balancer can perform health checks, we created this security group on the 'resource "aws_security_group" "alb_sg"' block down below and pass the security group id to the alb security_groups argument value:
  */
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_security_group" "alb_sg" {
  name = "${var.cluster_name}-alb-sg"
  description = "${var.cluster_name} ALB security group"
  vpc_id = data.aws_vpc.default.id

  tags = {
    Name = "${var.cluster_name} ALB security group"
  }

  // Ultimately we pass the sg id to the alb security_groups argument value
}

resource "aws_security_group_rule" "alb_sg_allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb_sg.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "alb_sg_allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb_sg.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

// Now we need to define the listener, the target group and the listerner rules, each has its own terraform resource:

// Let's define a listener for this ALB using the aws_lb_listener resource. This listener configures the ALB to listen on the default HTTP port, port 80, use HTTP as the protocol, and send a simple 404 page as the default response for requests that don’t match any listener rules.
resource "aws_lb_listener" "alb_http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = local.http_port
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

// Next, you need to create a target group for your ASG using the aws_lb_target_group resource:

resource "aws_lb_target_group" "alb_target_group" {
  name     = "${var.cluster_name}-target-grp"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  /*
  This target group will health check your Instances by periodically sending an HTTP request to each Instance and will consider the Instance “healthy” only if the Instance returns a response that matches the configured matcher (e.g., you can configure a matcher to look for a 200 OK response). If an Instance fails to respond, perhaps because that Instance has gone down or is overloaded, it will be marked as “unhealthy,” and the target group will automatically stop sending traffic to it to minimize disruption for your users.
  */

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  /*
  How does the target group know which EC2 Instances to send requests to? You could attach a static list of EC2 Instances to the target group using the aws_lb_target_group_attachment resource, but with an ASG, Instances can launch or terminate at any time, so a static list won’t work. Instead, you can take advantage of the first-class integration between the ASG and the ALB. Go back to the aws_autoscaling_group resource and set its target_group_arns argument to point at your new target group as follow:
  target_group_arns = aws_lb_target_group.alb_target_group.arn
  */
}

// Finally, it’s time to tie all these pieces together by creating listener rules using the aws_lb_listener_rule resource:

resource "aws_lb_listener_rule" "alb_listener_rules" {
  // The following code adds a listener rule that sends requests that match any path to the target group that contains your ASG.
  listener_arn = aws_lb_listener.alb_http_listener.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name  = "${var.cluster_name}-scale-out-during-business-hours"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 10
  recurrence             = "0 9 * * *"
  autoscaling_group_name = aws_autoscaling_group.asg_conf.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name  = "${var.cluster_name}-scale-in-at-night"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 2
  recurrence             = "0 17 * * *"
  autoscaling_group_name = aws_autoscaling_group.asg_conf.name
}