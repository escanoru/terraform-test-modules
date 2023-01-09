provider "aws" {
  region = "us-east-1"
}

module "asg" {
  source = "../../modules/cluster/asg-rolling-deploy"

  vpc_id               = data.aws_vpc.vpc.id
  cluster_name         = var.cluster_name
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = "t2.micro"

  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  enable_autoscaling   = false

  subnet_ids           = data.aws_subnets.subnets.ids
}
