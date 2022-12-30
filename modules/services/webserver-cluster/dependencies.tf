data "aws_vpc" "default" {
  // We use 'default = true' to query the available information of the default VPC
  default = true
}

data "aws_subnets" "default" {

  // With the filter below we query the existent subnets on the defaul VPC(which was queried using the aws_vpc data source)
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id] // Ultimately this value gets passed in vpc_zone_identifier
  }
}

data "terraform_remote_state" "db" { // Read the state file from 05_file_isolation/stage/data-stores/mysql 
  backend = "s3"

  config = {
    bucket         = var.db_remote_state_bucket
    key            = var.db_remote_state_key
    region         = var.db_remote_state_bucket_aws_region
  }
}