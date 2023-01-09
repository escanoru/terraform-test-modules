terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

module "asg" {
  source = "../../cluster/asg-rolling-deploy"

  vpc_id              = var.vpc_id
  cluster_name        = "hello-world-${var.environment}"
  ami                 = var.ami
  instance_type       = var.instance_type

  user_data           = templatefile("${path.module}/user-data.sh", {
    server_text       = var.server_text
    db_address        = data.terraform_remote_state.db.outputs.address
    db_port           = data.terraform_remote_state.db.outputs.port
    db_engine         = data.terraform_remote_state.db.outputs.engine
    db_engine_version = data.terraform_remote_state.db.outputs.db_engine_version
    server_port       = var.server_port
    
  })

  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  enable_autoscaling  = var.enable_autoscaling

  subnet_ids          = var.subnet_ids
  target_group_arns   = [aws_lb_target_group.asg.arn]
  health_check_type   = "ELB"

  custom_tags         = var.custom_tags
}

module "alb" {
  source = "../../networking/alb"

  alb_name   = "hello-world-${var.environment}"
  vpc_id        = var.vpc_id
  subnet_ids = var.subnet_ids
}

resource "aws_lb_target_group" "asg" {
  name     = "hello-world-${var.environment}"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

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

resource "aws_lb_listener_rule" "asg" {
  // The following code adds a listener rule that sends requests that match any path to the target group that contains your ASG.
  listener_arn = module.alb.alb_http_listener_arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

