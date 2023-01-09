
data "aws_vpc" "vpc" {
    // We use 'default = true' to query the available information of the default VPC
    default = true
}

data "aws_subnets" "subnets" {
    filter {
        name   = "vpc-id"
        values = [data.aws_vpc.vpc.id]
    }
}

data "aws_ami" "ubuntu" {
    most_recent = true
    owners      = ["099720109477"] # Canonical https://ubuntu.com/server/docs/cloud-images/amazon-ec2

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
}
